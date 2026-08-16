ActiveAdmin.register HomePageSectionSetting do
  menu parent: "Page d'accueil", label: "Paramètres", priority: 10

  permit_params :home_page_section_id, :key, :value

  controller do
    def new
      @home_page_section_setting = HomePageSectionSetting.new
      if params[:home_page_section_setting] && params[:home_page_section_setting][:home_page_section_id]
        @home_page_section_setting.home_page_section_id = params[:home_page_section_setting][:home_page_section_id]
      end
      super
    end
  end

  actions :all, except: []

  filter :home_page_section
  filter :key
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :key
    column :value do |setting|
      truncate(setting.value, length: 50)
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section do |setting|
        link_to setting.home_page_section.title, admin_home_page_section_path(setting.home_page_section) if setting.home_page_section
      end
      row :key
      row :value do |setting|
        simple_format(setting.value)
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations du paramètre" do
      f.input :home_page_section
      f.input :key, hint: "Promo carousel : item_ids, countdown_date, category_label, title, subtitle, description, discount_text, discount_suffix, image"
      f.input :value, as: :text, hint: "item_ids : liste d'IDs séparés par des virgules (ex: 12, 45, 78). countdown_date : ISO8601. image : chemin d'asset."
    end
    f.actions
  end
end
