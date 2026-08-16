ActiveAdmin.register SiteSetting do
  menu parent: "Paramètres Système", priority: 5, label: "SEO & Contenu Site"

  permit_params :key, :label, :description, :kind, :value_fr, :value_en, :position

  config.sort_order = "position_asc"

  filter :key
  filter :label
  filter :kind, as: :select, collection: SiteSetting::KINDS

  index do
    selectable_column
    column :position
    column :key
    column :label
    column("Valeur FR") { |s| truncate(s.value_fr.to_s, length: 80) }
    column("Valeur EN") { |s| truncate(s.value_en.to_s, length: 80) }
    column :kind
    column :updated_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :key
      row :label
      row :description
      row :kind
      row("Valeur FR") { |s| simple_format(s.value_fr.to_s) }
      row("Valeur EN") { |s| simple_format(s.value_en.to_s) }
      row :position
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Paramètre" do
      f.input :key, hint: "Identifiant technique, ex: seo.home.title"
      f.input :label, hint: "Nom affiché dans l'admin"
      f.input :description, hint: "Petite explication pour l'éditeur"
      f.input :kind, as: :select, collection: SiteSetting::KINDS, include_blank: false
      f.input :position
    end

    input_as = f.object.kind == "textarea" ? :text : :string
    f.inputs "Contenus" do
      f.input :value_fr, label: "Valeur FR", as: input_as
      f.input :value_en, label: "Valeur EN", as: input_as
    end

    f.actions
  end
end
