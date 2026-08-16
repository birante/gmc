# frozen_string_literal: true

# Query pour lire les catégories de produits
#
# Usage:
#   query = ProductCategoriesQuery.new
#   category = query.find_by_id(id)
#   categories = query.top_categories
class ProductCategoriesQuery
  def find_by_id(id)
    ProductCategory.find_by(id: id)
  end

  def find_by_slug(slug)
    ProductCategory.friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def top_categories(limit: 8)
    ProductCategory.where(is_active: true)
                   .with_attached_icon
                   .order(:position, :name)
                   .limit(limit)
  end

  # Sub-categories à afficher dans la rangée "Top Categories" sur la page de listing
  # global /fr/produits. On préfère des sub-categories aux top-categories parce que
  # celles-ci ont des icônes uploadées (les top-categories non) → évite le placeholder SVG.
  # Joint sur l'icon attachment pour ne lister que celles qui ont une icône réellement
  # attachée, et eager-load la parent category pour générer les liens drill-down.
  def featured_sub_categories(limit: 8)
    ProductSubCategory.where(is_active: true)
                      .joins(:icon_attachment)
                      .distinct
                      .includes(:product_category, icon_attachment: :blob)
                      .order(:position, :name)
                      .limit(limit)
  end

  def active_sub_categories(category)
    category.sub_categories.where(is_active: true)
            .with_attached_icon
            .order(:position, :name)
  end

  def sub_category_ids_for_category(category)
    category.sub_categories.where(is_active: true).pluck(:id)
  end

  def find_sub_category_by_id(id)
    ProductSubCategory.find_by(id: id)
  end
end
