# frozen_string_literal: true

module Client
  class ReviewsController < BaseController
    before_action :set_review, only: [ :update, :destroy, :mark_as_helpful ]
    before_action :set_item, only: [ :create ]
    before_action :ensure_item_ownership, only: [ :create ]

    def index
      @reviews = Review.approved
                      .includes(:user, :item, :order_item)
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(20)

      if params[:item_id].present?
        @item = Item.find_by(id: params[:item_id])
        @reviews = @reviews.where(item: @item) if @item
      end
    end

    def my_reviews
      @reviews = current_user.reviews
                             .includes(:item, :order_item)
                             .order(created_at: :desc)
                             .page(params[:page])
                             .per(20)
    end

    def create
      @review = current_user.reviews.build(review_params)
      @review.item = @item
      @review.status = "approved" # Les avis sont approuvés par défaut

      if @review.save
        redirect_back(fallback_location: client_item_path(@item), notice: "Votre avis a été publié avec succès.")
      else
        redirect_back(fallback_location: client_item_path(@item), alert: "Erreur lors de la soumission de l'avis: #{@review.errors.full_messages.join(', ')}")
      end
    end

    def update
      unless @review.can_be_edited_by?(current_user)
        redirect_back(fallback_location: client_item_path(@review.item), alert: "Vous ne pouvez plus modifier cet avis.")
        return
      end

      if @review.update(review_params)
        redirect_back(fallback_location: client_item_path(@review.item), notice: "Votre avis a été mis à jour.")
      else
        redirect_back(fallback_location: client_item_path(@review.item), alert: "Erreur lors de la mise à jour: #{@review.errors.full_messages.join(', ')}")
      end
    end

    def destroy
      unless @review.user == current_user
        redirect_back(fallback_location: client_item_path(@review.item), alert: "Vous ne pouvez pas supprimer cet avis.")
        return
      end

      item = @review.item
      @review.destroy
      redirect_back(fallback_location: client_item_path(item), notice: "Votre avis a été supprimé.")
    end

    def mark_as_helpful
      @review.mark_as_helpful!
      render json: { helpful_count: @review.helpful_count }
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def set_item
      @item = Item.friendly.find(params[:item_id])
    end

    def ensure_item_ownership
      # Vérifier que l'utilisateur a bien acheté ce produit
      unless current_user.orders.joins(:order_items).where(order_items: { item_id: @item.id, delivery_status: "delivered" }).exists?
        redirect_back(fallback_location: client_item_path(@item), alert: "Vous devez avoir acheté et reçu ce produit pour laisser un avis.")
        return
      end

      # Vérifier qu'il n'a pas déjà laissé un avis pour ce produit
      if current_user.reviews.where(item: @item).exists?
        redirect_back(fallback_location: client_item_path(@item), alert: "Vous avez déjà laissé un avis pour ce produit.")
        nil
      end
    end

    def review_params
      params.require(:review).permit(:rating, :comment, :order_item_id, images: [])
    end
  end
end
