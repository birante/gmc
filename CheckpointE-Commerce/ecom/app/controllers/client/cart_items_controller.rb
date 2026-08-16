module Client
  class CartItemsController < BaseController
    skip_before_action :authenticate_client!
    allow_unauthenticated_access

    def create
      Rails.logger.info("🛒 [Client::CartItemsController] Ajout article au panier - item_id: #{params[:item_id]}, variant_id: #{params[:item_variant_id]}, user_id: #{current_user&.id}")

      begin
        @item = Item.find(params[:item_id])
      rescue ActiveRecord::RecordNotFound
        Rails.logger.error("❌ [Client::CartItemsController] Article non trouvé - item_id: #{params[:item_id]}")
        respond_to do |format|
          format.html { redirect_to client_items_path, alert: "Article non trouvé" }
          format.turbo_stream { head :not_found }
        end
        return
      end

      @variant = if params[:item_variant_id].present?
        @item.variants.find_by(id: params[:item_variant_id])
      else
        @item.variants.first
      end

      unless @variant
        Rails.logger.warn("⚠️ [Client::CartItemsController] Variante non trouvée - item_id: #{@item.id}")
        respond_to do |format|
          format.html { redirect_to client_item_path(@item), alert: "Aucune variante disponible" }
          format.turbo_stream { head :unprocessable_entity }
        end
        return
      end

      # Vérifier si le stock est disponible
      if @variant.stock_quantity <= 0
        respond_to do |format|
          format.html { redirect_to client_item_path(@item), alert: "Ce produit est en rupture de stock" }
          format.turbo_stream { head :unprocessable_entity }
        end
        return
      end

      @cart_item = current_cart.cart_items.find_or_initialize_by(
        item: @item,
        item_variant: @variant
      )
      quantity_change = (params[:quantity] || 1).to_i

      if @cart_item.new_record?
        # Si c'est un nouvel article, la quantité doit être positive
        requested_quantity = [ quantity_change, 1 ].max

        # Vérifier que la quantité demandée ne dépasse pas le stock
        if requested_quantity > @variant.stock_quantity
          respond_to do |format|
            format.html { redirect_to client_item_path(@item), alert: "Stock insuffisant. Seulement #{@variant.stock_quantity} disponible(s)" }
            format.turbo_stream { head :unprocessable_entity }
          end
          return
        end

        @cart_item.quantity = requested_quantity
        # Utiliser le prix actuel (promo ou normal) au lieu du prix de base
        @cart_item.unit_price = @variant.respond_to?(:current_price) ? @variant.current_price : @variant.price
      else
        # Si l'article existe déjà, on ajoute/soustrait la quantité
        new_quantity = @cart_item.quantity + quantity_change

        # La quantité ne peut pas être négative ou nulle
        if new_quantity <= 0
          removed_quantity = @cart_item.quantity
          @cart_item.destroy
          track_cart_event("item_removed_from_cart", item: @item, unit_price: @cart_item.unit_price, quantity: removed_quantity)
          # Recharger le panier pour avoir les valeurs à jour
          current_cart.reload
          @item_removed = true
        respond_to do |format|
          redirect_url = if request.referer.present?
            begin
              redirect_uri = URI.parse(request.referer)
              if redirect_uri.query.present?
                params = URI.decode_www_form(redirect_uri.query).to_h
                params["cart"] = "open"
                redirect_uri.query = URI.encode_www_form(params)
              else
                redirect_uri.query = "cart=open"
              end
              redirect_uri.to_s
            rescue URI::InvalidURIError
              root_path(cart: "open")
            end
          else
            root_path(cart: "open")
          end
          format.html { redirect_to redirect_url, notice: "Article retiré du panier" }
          format.turbo_stream { render :create }
        end
          return
        end

        # Vérifier que la nouvelle quantité ne dépasse pas le stock
        if new_quantity > @variant.stock_quantity
          respond_to do |format|
            redirect_url = if request.referer.present?
              begin
                redirect_uri = URI.parse(request.referer)
                if redirect_uri.query.present?
                  params = URI.decode_www_form(redirect_uri.query).to_h
                  params["cart"] = "open"
                  redirect_uri.query = URI.encode_www_form(params)
                else
                  redirect_uri.query = "cart=open"
                end
                redirect_uri.to_s
              rescue URI::InvalidURIError
                root_path(cart: "open")
              end
            else
              root_path(cart: "open")
            end
            format.html { redirect_to redirect_url, alert: "Stock insuffisant. Seulement #{@variant.stock_quantity} disponible(s)" }
            format.turbo_stream { head :unprocessable_entity }
          end
          return
        end

        @cart_item.quantity = new_quantity
      end

      if @cart_item.save
        Rails.logger.info("✅ [Client::CartItemsController] Article ajouté au panier avec succès - cart_item_id: #{@cart_item.id}, quantité: #{@cart_item.quantity}")
        delta = @cart_item.previously_new_record? ? @cart_item.quantity : quantity_change
        if delta.positive?
          track_cart_event("item_added_to_cart", item: @item, unit_price: @cart_item.unit_price, quantity: delta)
        elsif delta.negative?
          track_cart_event("item_removed_from_cart", item: @item, unit_price: @cart_item.unit_price, quantity: -delta)
        end
        # Recharger le panier pour avoir les valeurs à jour
        current_cart.reload
        respond_to do |format|
          redirect_url = request.referer.presence || root_path
          format.html { redirect_to redirect_url, notice: "Article ajouté au panier" }
          format.turbo_stream { render :create }
        end
      else
        Rails.logger.error("❌ [Client::CartItemsController] Échec ajout article au panier - erreurs: #{@cart_item.errors.full_messages.join(', ')}")
        respond_to do |format|
          format.html { redirect_to client_item_path(@item), alert: "Erreur lors de l'ajout au panier" }
          format.turbo_stream { head :unprocessable_entity }
        end
      end
    end

    def update
      @cart_item = current_cart.cart_items.find(params[:id])
      @cart_item_id = @cart_item.id
      quantity_change = (params[:quantity] || 1).to_i

      new_quantity = @cart_item.quantity + quantity_change

      # Si la quantité devient 0 ou négative, supprimer l'article
      if new_quantity <= 0
        @item_id = @cart_item.item_id
        @item_variant_id = @cart_item.item_variant_id
        @item_size  = params[:size].presence  || "md"
        @item_style = params[:style].presence || "outline"
        @item_show_icon = params[:show_icon] != "false"
        removed_quantity = @cart_item.quantity
        removed_item = @cart_item.item
        removed_unit_price = @cart_item.unit_price
        @cart_item.destroy
        track_cart_event("item_removed_from_cart", item: removed_item, unit_price: removed_unit_price, quantity: removed_quantity)
        current_cart.reload
        @item_removed = true
        respond_to do |format|
          redirect_url = if request.referer.present?
            begin
              redirect_uri = URI.parse(request.referer)
              if redirect_uri.query.present?
                params = URI.decode_www_form(redirect_uri.query).to_h
                params["cart"] = "open"
                redirect_uri.query = URI.encode_www_form(params)
              else
                redirect_uri.query = "cart=open"
              end
              redirect_uri.to_s
            rescue URI::InvalidURIError
              root_path(cart: "open")
            end
          else
            root_path(cart: "open")
          end
          format.html { redirect_to redirect_url, notice: "Article retiré du panier" }
          format.turbo_stream { render :update }
        end
        return
      end

      # Vérifier que la nouvelle quantité ne dépasse pas le stock
      variant = @cart_item.variant
      if new_quantity > variant.stock_quantity
        respond_to do |format|
          redirect_url = if request.referer.present?
            begin
              redirect_uri = URI.parse(request.referer)
              if redirect_uri.query.present?
                params = URI.decode_www_form(redirect_uri.query).to_h
                params["cart"] = "open"
                redirect_uri.query = URI.encode_www_form(params)
              else
                redirect_uri.query = "cart=open"
              end
              redirect_uri.to_s
            rescue URI::InvalidURIError
              root_path(cart: "open")
            end
          else
            root_path(cart: "open")
          end
          format.html { redirect_to redirect_url, alert: "Stock insuffisant. Seulement #{variant.stock_quantity} disponible(s)" }
          format.turbo_stream { head :unprocessable_entity }
        end
        return
      end

      # Mettre à jour la quantité et recalculer le prix (au cas où la promo aurait changé)
      variant = @cart_item.variant
      current_unit_price = variant.respond_to?(:current_price) ? variant.current_price : variant.price
      if @cart_item.update(quantity: new_quantity, unit_price: current_unit_price)
        if quantity_change.positive?
          track_cart_event("item_added_to_cart", item: @cart_item.item, unit_price: @cart_item.unit_price, quantity: quantity_change)
        elsif quantity_change.negative?
          track_cart_event("item_removed_from_cart", item: @cart_item.item, unit_price: @cart_item.unit_price, quantity: -quantity_change)
        end
        current_cart.reload
        @item_id         = @cart_item.item_id
        @item_variant_id = @cart_item.item_variant_id
        @item_size       = params[:size].presence  || "md"
        @item_style      = params[:style].presence || "outline"
        @item_show_icon  = params[:show_icon] != "false"
        @quantity_change = quantity_change
        respond_to do |format|
          format.html { redirect_to request.referer.presence || root_path, notice: "Quantité mise à jour" }
          format.turbo_stream { render :update }
        end
      else
        respond_to do |format|
          redirect_url = if request.referer.present?
            begin
              redirect_uri = URI.parse(request.referer)
              if redirect_uri.query.present?
                params = URI.decode_www_form(redirect_uri.query).to_h
                params["cart"] = "open"
                redirect_uri.query = URI.encode_www_form(params)
              else
                redirect_uri.query = "cart=open"
              end
              redirect_uri.to_s
            rescue URI::InvalidURIError
              root_path(cart: "open")
            end
          else
            root_path(cart: "open")
          end
          format.html { redirect_to redirect_url, alert: "Erreur lors de la mise à jour" }
          format.turbo_stream { head :unprocessable_entity }
        end
      end
    end

    def destroy
      @cart_item = current_cart.cart_items.find(params[:id])
      @cart_item_id = @cart_item.id
      @item_id = @cart_item.item_id
      @item_variant_id = @cart_item.item_variant_id
      Rails.logger.info("🗑️ [Client::CartItemsController] Suppression article du panier - cart_item_id: #{@cart_item_id}, item_id: #{@cart_item.item_id}")
      removed_quantity = @cart_item.quantity
      removed_item = @cart_item.item
      removed_unit_price = @cart_item.unit_price
      @cart_item.destroy
      track_cart_event("item_removed_from_cart", item: removed_item, unit_price: removed_unit_price, quantity: removed_quantity)
      current_cart.reload
      @item_removed = true
      respond_to do |format|
        redirect_url = if request.referer.present?
          begin
            redirect_uri = URI.parse(request.referer)
            if redirect_uri.query.present?
              params = URI.decode_www_form(redirect_uri.query).to_h
              params["cart"] = "open"
              redirect_uri.query = URI.encode_www_form(params)
            else
              redirect_uri.query = "cart=open"
            end
            redirect_uri.to_s
          rescue URI::InvalidURIError
            root_path(cart: "open")
          end
        else
          root_path(cart: "open")
        end
        format.html { redirect_to redirect_url, notice: "Article retiré du panier" }
        format.turbo_stream { render :update }
      end
    end

    private

    def track_cart_event(event_name, item:, unit_price:, quantity:)
      return if quantity.to_i <= 0 || item.nil?

      track_event(event_name,
        item_id: item.id,
        item_name: item.name,
        item_price: unit_price,
        quantity: quantity,
        shop_id: item.shop_id
      )
    end
  end
end
