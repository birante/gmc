module Vendors
  class ItemsController < BaseController
    def index
      # @vendor est déjà positionné par Vendors::BaseController#set_vendor_for_view
      # (vendor connecté ou vendor du collaborateur en cross-portail).
      return @items = Item.none unless @vendor

      # Recherche et filtrage des items
      query = VendorItemsQuery.new(
        vendor: @vendor,
        shop_condition: @shop_condition,
        shop_value: @shop_value
      )
      @items = query.search(
        filters: {
          search: params[:search],
          validation_status: params[:validation_status],
          page: params[:page],
          per_page: params[:per_page]
        },
        paginate: true
      )

      # Variables pour le formulaire
      @item = @current_shop.items.build if @current_shop
      form_data = Vendors::ItemFormDataService.new(vendor: @vendor, shop: @current_shop).call
      @product_categories = form_data[:product_categories]
      @currencies = form_data[:currencies]
      @product_attributes = form_data[:product_attributes]
      @categories_json = form_data[:categories_json]
    end

    def new
      @vendor = current_vendor
      Rails.logger.info("📌 [Vendors::ItemsController#new] current_shop: #{@current_shop&.id}, vendor: #{@vendor&.id}")

      @item = @current_shop.items.build if @current_shop

      form_data = Vendors::ItemFormDataService.new(vendor: @vendor, shop: @current_shop).call
      @product_categories = form_data[:product_categories]
      @currencies = form_data[:currencies]
      @product_attributes = form_data[:product_attributes]
      @categories_json = form_data[:categories_json]
    end

    def create
      @vendor = current_vendor
      return redirect_to url_with_shop(vendors_items_path, @current_shop), alert: t("vendors.items.shop_required") unless @current_shop

      service = Vendors::ItemCreationService.new(
        shop: @current_shop,
        params: item_params,
        commit: params[:commit]
      )
      result = service.call

      if result.success?
        handle_successful_creation(result.item)
      else
        handle_failed_creation(result.item, result.errors)
      end
    end

    def show
      # @vendor positionné par Vendors::BaseController#set_vendor_for_view
      @item = @current_shop&.items&.friendly.find(params[:id]) if @current_shop
      return authorize_vendor_item! unless @item

      @variants = @item.variants.includes(attribute_values: :item_attribute)
      @item_attributes = @item.item_attributes.includes(:attribute_values).ordered
    end

    def purge_image
      @item = @current_shop&.items&.friendly.find(params[:id])
      return authorize_vendor_item! unless @item

      image = @item.images.find(params[:image_id])
      image.purge

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to url_with_shop(edit_vendors_item_path(@item), @current_shop), notice: "Image supprimée avec succès" }
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.turbo_stream { head :not_found }
        format.html { redirect_to url_with_shop(edit_vendors_item_path(@item), @current_shop), alert: "Image non trouvée" }
      end
    end

    def edit
      @vendor = current_vendor
      @item = @current_shop&.items&.friendly.find(params[:id]) if @current_shop
      return authorize_vendor_item! unless @item

      form_data = Vendors::ItemFormDataService.new(vendor: @vendor, shop: @current_shop).call
      @product_categories = form_data[:product_categories]
      @currencies = form_data[:currencies]
      @categories_json = form_data[:categories_json]
      @item_attributes = @item.item_attributes.includes(:attribute_values).ordered
      @variants = @item.variants.includes(attribute_values: :item_attribute).order(is_default: :desc, created_at: :asc)
    end

    def manage
      @vendor = current_vendor
      @item = @current_shop&.items&.friendly.find(params[:id]) if @current_shop
      return authorize_vendor_item! unless @item

      @item_attributes = @item.item_attributes.includes(:attribute_values).ordered
      @variants = @item.variants.includes(attribute_values: :item_attribute).order(is_default: :desc, created_at: :asc)
      @min_price = @item.variants.minimum(:price)
      @max_price = @item.variants.maximum(:price)

      @total_sales = @item.order_items.joins(:order).where(orders: { status: [ "completed", "delivered" ] }).sum(:quantity)
      @total_revenue = @item.order_items.joins(:order).where(orders: { status: [ "completed", "delivered" ] }).sum(:total_price)
      @total_views = @item.views_count || 0
    end

    def update
      @vendor = current_vendor
      @item = @current_shop&.items&.friendly.find(params[:id]) if @current_shop
      return authorize_vendor_item! unless @item

      service = Vendors::ItemUpdateService.new(item: @item, params: item_params)
      result = service.call

      if result.success?
        handle_successful_update(result.status_changed)
      else
        handle_failed_update(result.item, result.errors)
      end
    end

    def generate_variants
      @vendor = current_vendor
      @item = @current_shop&.items&.friendly.find(params[:id]) if @current_shop
      return authorize_vendor_item! unless @item

      default_price = @item.default_variant&.price
      default_stock = @item.default_variant&.stock_quantity

      created_count = @item.generate_variants!(default_price, default_stock).count
      Rails.logger.info("🎯 [Vendors::ItemsController] Génération de #{created_count} variantes - item_id: #{@item.id}")

      redirect_with_return_to(t("vendors.items.variants_generated", count: created_count))
    end

    def generate_ai_preview
      @vendor = current_vendor
      return redirect_to url_with_shop(vendors_items_path, @current_shop), alert: t("vendors.items.shop_required") unless @current_shop
      return redirect_to url_with_shop(vendors_items_path, @current_shop), alert: t("vendors.items.ai_preview_unavailable") unless @current_shop.capabilities.ai_title_description_enabled?

      # Préparer les paramètres pour la preview
      item_params_for_preview = {
        name: params[:name],
        description: params[:description],
        category_name: ProductSubCategory.find_by(id: params[:product_sub_category_id])&.product_category&.name,
        sub_category_name: ProductSubCategory.find_by(id: params[:product_sub_category_id])&.name,
        price: params[:default_price] || params[:price],
        currency_code: Currency.find_by(id: params[:currency_id])&.code
      }

      service = ItemAIPreviewService.new(item_params: item_params_for_preview)
      result = service.call

      if result.success?
        render json: { success: true, preview: result.preview_data }
      else
        render json: { success: false, errors: result.errors }, status: :unprocessable_entity
      end
    end

    def retry_ai_enrichment
      @vendor = current_vendor
      @item = @current_shop&.items&.friendly.find(params[:id]) if @current_shop
      return authorize_vendor_item! unless @item

      @item.retry_ai_enrichment!

      redirect_to url_with_shop(vendors_item_path(@item), @current_shop),
                  notice: t("vendors.items.ai_enrichment_relaunched")
    end

    # GET /vendors/items/download_template
    # Renvoie un CSV vierge (UTF-8 + BOM Excel) avec les en-têtes attendus
    # et 2 lignes d'exemple — un produit simple + un produit à 2 variantes.
    def download_template
      send_data build_template_csv,
                filename: "modele_import_aa.csv",
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    end

    # GET /vendors/items/download_categories
    # Renvoie un CSV listant toutes les sous-catégories actives (avec leur
    # catégorie parente) pour aider le vendeur à remplir `sous_categorie`.
    def download_categories
      send_data build_categories_csv,
                filename: "categories_aa.csv",
                type: "text/csv; charset=utf-8",
                disposition: "attachment"
    end

    # POST /vendors/items/bulk_upload
    # Accepte un fichier CSV, délègue au service, redirige avec un flash
    # détaillant nb créés / nb ignorés / erreurs.
    def bulk_upload
      return redirect_to url_with_shop(vendors_items_path, @current_shop), alert: t("vendors.items.shop_required") unless @current_shop

      file = params[:file]
      unless file.respond_to?(:read)
        redirect_to url_with_shop(vendors_items_path, @current_shop), alert: t("vendors.items.bulk_upload.flash.no_file")
        return
      end

      result = Vendors::ItemBulkUploadService.new(shop: @current_shop, file: file).call

      message_parts = []
      message_parts << t("vendors.items.bulk_upload.flash.created", count: result.created_count) if result.created_count.positive?
      message_parts << t("vendors.items.bulk_upload.flash.skipped", count: result.skipped_count) if result.skipped_count.positive?
      message_parts << t("vendors.items.bulk_upload.flash.errors", details: result.errors.first(5).join(" | ")) if result.errors.any?

      flash_key = result.created_count.positive? ? :notice : :alert
      flash[flash_key] = message_parts.join(" — ").presence || t("vendors.items.bulk_upload.flash.empty")

      redirect_to url_with_shop(vendors_items_path, @current_shop)
    end

    private

    def build_template_csv
      headers = %w[
        nom description prix stock sous_categorie devise
        attribut_1 valeur_1 attribut_2 valeur_2
        prix_variante stock_variante
      ]
      rows = [
        [
          "Casquette en coton bio",
          "Casquette unisexe en coton biologique, taille unique",
          "4500", "20",
          "Accessoires",
          "XOF",
          "", "", "", "", "", ""
        ],
        [
          "T-shirt premium",
          "T-shirt 100% coton, coupe régulière",
          "7500", "0",
          "Vêtements hommes",
          "XOF",
          "Couleur", "Noir", "Taille", "M",
          "7500", "12"
        ],
        [
          "T-shirt premium",
          "", "", "",
          "", "",
          "Couleur", "Blanc", "Taille", "L",
          "8000", "8"
        ]
      ]
      csv = CSV.generate(col_sep: ",") do |out|
        out << headers
        rows.each { |row| out << row }
      end
      "\xEF\xBB\xBF" + csv # BOM UTF-8 pour Excel
    end

    def build_categories_csv
      categories = ProductCategory.where(is_active: true).includes(:sub_categories).order(:name)
      csv = CSV.generate(col_sep: ",") do |out|
        out << %w[categorie sous_categorie]
        categories.each do |cat|
          subs = cat.sub_categories.where(is_active: true).order(:name)
          if subs.any?
            subs.each { |sub| out << [ cat.name, sub.name ] }
          else
            out << [ cat.name, "" ]
          end
        end
      end
      "\xEF\xBB\xBF" + csv
    end

    def authorize_vendor_item!
      redirect_to url_with_shop(vendors_items_path, @current_shop), alert: t("common.unauthorized") unless @item
    end

    # Redirects to the manage page if `return_to=manage` param is set, otherwise to the item show page.
    def redirect_with_return_to(notice)
      if params[:return_to] == "manage"
        redirect_to url_with_shop(manage_vendors_item_path(@item), @current_shop), notice: notice
      else
        redirect_to url_with_shop(vendors_item_path(@item), @current_shop), notice: notice
      end
    end

    def handle_successful_creation(item)
      if item.variants.any?
        message = t("vendors.items.product_created_success", count: item.variants.count)
        redirect_to url_with_shop(vendors_item_path(item), @current_shop), notice: message
      else
        Rails.logger.warn("⚠️ [Vendors::ItemsController] Produit créé SANS variante - item_id: #{item.id}")
        redirect_to url_with_shop(edit_vendors_item_path(item), @current_shop),
                    alert: t("vendors.items.product_created_no_variant")
      end
    end

    def handle_failed_creation(item, errors)
      Rails.logger.warn("⚠️ [Vendors::ItemsController] Échec création - erreurs: #{errors.join(', ')}")

      # Préparer les données pour réafficher le formulaire
      query = VendorItemsQuery.new(
        vendor: @vendor,
        shop_condition: @shop_condition,
        shop_value: @shop_value
      )
      @items = query.search(
        filters: {
          search: params[:search],
          validation_status: params[:validation_status],
          page: params[:page],
          per_page: params[:per_page]
        },
        paginate: true
      )

      form_data = Vendors::ItemFormDataService.new(vendor: @vendor, shop: @current_shop).call
      @product_categories = form_data[:product_categories]
      @currencies = form_data[:currencies]
      @categories_json = form_data[:categories_json]

      render :index, status: :unprocessable_entity
    end

    def handle_successful_update(status_changed)
      notice = status_changed ? t("vendors.items.product_updated_success") : t("vendors.items.updated")
      redirect_with_return_to(notice)
    end

    def handle_failed_update(item, errors)
      Rails.logger.warn("⚠️ [Vendors::ItemsController] Échec mise à jour - erreurs: #{errors.join(', ')}")

      # Recharger l'item avec ses associations
      item.reload

      if params[:return_to] == "manage"
        # Redisplay the manage page with errors
        @item_attributes = item.item_attributes.includes(:attribute_values).ordered
        @variants = item.variants.includes(attribute_values: :item_attribute).order(is_default: :desc, created_at: :asc)
        @min_price = item.variants.minimum(:price)
        @max_price = item.variants.maximum(:price)
        @total_sales = item.order_items.joins(:order).where(orders: { status: [ "completed", "delivered" ] }).sum(:quantity)
        @total_revenue = item.order_items.joins(:order).where(orders: { status: [ "completed", "delivered" ] }).sum(:total_price)
        @total_views = item.views_count || 0
        render :manage, status: :unprocessable_entity
      else
        # Préparer les variables pour réafficher le formulaire
        form_data = Vendors::ItemFormDataService.new(vendor: @vendor, shop: @current_shop).call
        @product_categories = form_data[:product_categories]
        @currencies = form_data[:currencies]
        @categories_json = form_data[:categories_json]
        @item_attributes = item.item_attributes.includes(:attribute_values).ordered
        @variants = item.variants.includes(:attribute_values).order(is_default: :desc, created_at: :asc)

        render :edit, status: :unprocessable_entity
      end
    end

    def item_params
      params.require(:item).permit(
        :name,
        :description,
        :price,               # legacy field (mappé vers default_price)
        :stock_quantity,      # legacy field (mappé vers default_stock_quantity)
        :default_price,
        :default_stock_quantity,
        :product_sub_category_id,
        :currency_id,
        :is_on_sale,
        :sale_discount_percent,
        :sale_start_date,
        :sale_end_date,
        :main_image,
        images: [],
        item_attributes_attributes: [
          :id, :name, :position, :_destroy,
          { attribute_values_attributes: [ :id, :value, :position, :hex_code, :shop_color_id, :_destroy ] }
        ],
        variants_attributes: [
          :id, :sku, :price, :stock_quantity, :is_default, :sale_price, :_destroy,
          { combination_data: [] }
        ]
      )
    end
  end
end
