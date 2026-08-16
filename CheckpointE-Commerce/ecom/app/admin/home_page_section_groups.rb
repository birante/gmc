# frozen_string_literal: true

ActiveAdmin.register HomePageSectionGroup do
  menu parent: "Page d'accueil", label: "Groupes (Tendances)", priority: 6

  permit_params :home_page_section_id, :title, :link, :position, :is_active

  actions :all, except: []

  filter :home_page_section
  filter :title
  filter :is_active
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :title
    column :link
    column :position
    column "Actif" do |group|
      status_tag(group.is_active? ? "Oui" : "Non", class: group.is_active? ? "ok" : "error")
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section
      row :title
      row :link
      row :position
      row("Actif") { |group| group.is_active? ? "Oui" : "Non" }
      row :created_at
      row :updated_at
    end

    panel "Éléments du groupe" do
      div do
        link_to "Nouvel élément", new_admin_home_page_section_group_item_path(home_page_section_group_item: { home_page_section_group_id: resource.id }), class: "button"
      end
      table_for resource.home_page_section_group_items.order(:position) do
        column :id
        column :title
        column :link
        column :position
        column :created_at
        column "Actions" do |item|
          link_to "Voir", admin_home_page_section_group_item_path(item), class: "member_link view_link"
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Groupe (Tendances)" do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "trending_categories"),
              hint: "Choisir la section 'trending_categories'."
      f.input :title, label: "Titre du groupe", hint: "Ex: Électronique, Mode, Beauté"
      f.input :link, label: "Lien du groupe", hint: "Ex: /fr/categories/electronique"
      f.input :position, label: "Ordre", hint: "1 à 4 (4 groupes requis)"
      f.input :is_active, label: "Actif"
    end

    f.actions
  end
end
