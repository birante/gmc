# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_06_120100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "add_ons", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.text "description"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_add_ons_on_code", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "street_address", null: false
    t.string "city"
    t.string "postal_code"
    t.string "country", default: "SN"
    t.boolean "is_default", default: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.bigint "delivery_zone_id"
    t.index ["delivery_zone_id"], name: "index_addresses_on_delivery_zone_id"
    t.index ["slug"], name: "index_addresses_on_slug", unique: true
    t.index ["user_id", "is_default"], name: "index_addresses_on_user_id_and_is_default"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "manager", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["role"], name: "index_admin_users_on_role"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.string "user_type"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "shop_id"
    t.bigint "item_id"
    t.index ["item_id"], name: "index_ahoy_events_on_item_id"
    t.index ["name", "item_id"], name: "index_ahoy_events_on_name_and_item_id"
    t.index ["name", "shop_id"], name: "index_ahoy_events_on_name_and_shop_id"
    t.index ["name", "time", "item_id"], name: "index_ahoy_events_on_name_and_time_and_item_id"
    t.index ["name", "time", "shop_id"], name: "index_ahoy_events_on_name_and_time_and_shop_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["shop_id"], name: "index_ahoy_events_on_shop_id"
    t.index ["user_type", "user_id"], name: "index_ahoy_events_on_user"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.string "user_type"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "started_at"
    t.index ["user_type", "user_id"], name: "index_ahoy_visits_on_user"
    t.index ["user_type", "user_id"], name: "index_ahoy_visits_on_user_type_and_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "attribute_values", force: :cascade do |t|
    t.bigint "item_attribute_id", null: false
    t.string "value", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hex_code", limit: 7
    t.bigint "shop_color_id"
    t.index ["item_attribute_id", "value"], name: "index_attribute_values_on_item_attribute_id_and_value", unique: true
    t.index ["item_attribute_id"], name: "index_attribute_values_on_item_attribute_id"
    t.index ["shop_color_id"], name: "index_attribute_values_on_shop_color_id"
  end

  create_table "blog_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "position", default: 0
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_blog_categories_on_active"
    t.index ["slug"], name: "index_blog_categories_on_slug", unique: true
  end

  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "excerpt"
    t.string "author_name"
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.bigint "blog_category_id"
    t.integer "views_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_category_id"], name: "index_blog_posts_on_blog_category_id"
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["status"], name: "index_blog_posts_on_status"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "item_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 12, scale: 2
    t.decimal "total_price", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "item_variant_id"
    t.index ["cart_id", "item_variant_id"], name: "index_cart_items_on_cart_id_and_item_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["item_id"], name: "index_cart_items_on_item_id"
    t.index ["item_variant_id"], name: "index_cart_items_on_item_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_carts_on_slug", unique: true
    t.index ["user_id", "status"], name: "index_carts_on_user_id_and_status"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "subject"
    t.text "message", null: false
    t.string "status", default: "new", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contact_messages_on_created_at"
    t.index ["status"], name: "index_contact_messages_on_status"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "code", limit: 3
    t.string "symbol", limit: 10
    t.string "name"
    t.string "thousands_separator", limit: 1
    t.string "decimal_separator", limit: 1
    t.boolean "symbol_precedes_amount"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "delivery_categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code", null: false
    t.index ["code"], name: "index_delivery_categories_on_code", unique: true
    t.index ["display_order"], name: "index_delivery_categories_on_display_order"
    t.index ["name"], name: "index_delivery_categories_on_name", unique: true
  end

  create_table "delivery_prices", force: :cascade do |t|
    t.bigint "delivery_zone_id", null: false
    t.bigint "delivery_category_id", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_category_id"], name: "index_delivery_prices_on_delivery_category_id"
    t.index ["delivery_zone_id", "delivery_category_id"], name: "index_delivery_prices_on_zone_and_category", unique: true
    t.index ["delivery_zone_id"], name: "index_delivery_prices_on_delivery_zone_id"
  end

  create_table "delivery_slots", force: :cascade do |t|
    t.time "start_time"
    t.time "end_time"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_zones", force: :cascade do |t|
    t.string "name"
    t.decimal "base_fee", precision: 8, scale: 2, default: "0.0"
    t.integer "min_delivery_time", default: 0
    t.integer "max_delivery_time", default: 0
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["name"], name: "index_delivery_zones_on_name", unique: true
  end

  create_table "employee_shops", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "shop_id", null: false
    t.boolean "is_primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "shop_id"], name: "index_employee_shops_on_employee_id_and_shop_id", unique: true
    t.index ["employee_id"], name: "index_employee_shops_on_employee_id"
    t.index ["shop_id"], name: "index_employee_shops_on_shop_id"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "country_code", default: "221"
    t.string "phone_number"
    t.string "role", default: "cashier", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["status"], name: "index_employees_on_status"
    t.index ["vendor_id"], name: "index_employees_on_vendor_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "hero_slider_slides", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "badge_text"
    t.string "badge_bg_color"
    t.string "badge_text_color"
    t.string "title"
    t.string "cta_text"
    t.string "cta_link"
    t.string "gradient"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_hero_slider_slides_on_home_page_section_id"
  end

  create_table "home_page_section_categories", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.bigint "product_category_id", null: false
    t.bigint "product_sub_category_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_home_page_section_categories_on_home_page_section_id"
    t.index ["product_category_id"], name: "index_home_page_section_categories_on_product_category_id"
    t.index ["product_sub_category_id"], name: "index_home_page_section_categories_on_product_sub_category_id"
  end

  create_table "home_page_section_group_items", force: :cascade do |t|
    t.bigint "home_page_section_group_id", null: false
    t.string "title", null: false
    t.string "link", null: false
    t.integer "position", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_group_id"], name: "idx_on_home_page_section_group_id_ced0e9e740"
    t.index ["is_active"], name: "index_home_page_section_group_items_on_is_active"
    t.index ["position"], name: "index_home_page_section_group_items_on_position"
  end

  create_table "home_page_section_groups", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "title", null: false
    t.string "link", null: false
    t.integer "position", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_home_page_section_groups_on_home_page_section_id"
    t.index ["is_active"], name: "index_home_page_section_groups_on_is_active"
    t.index ["position"], name: "index_home_page_section_groups_on_position"
  end

  create_table "home_page_section_items", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "title", null: false
    t.string "link", null: false
    t.integer "position", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_home_page_section_items_on_home_page_section_id"
    t.index ["is_active"], name: "index_home_page_section_items_on_is_active"
    t.index ["position"], name: "index_home_page_section_items_on_position"
  end

  create_table "home_page_section_products", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.bigint "item_id", null: false
    t.integer "position", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id", "item_id"], name: "index_hp_section_products_on_section_and_item", unique: true
    t.index ["home_page_section_id"], name: "index_home_page_section_products_on_home_page_section_id"
    t.index ["is_active"], name: "index_home_page_section_products_on_is_active"
    t.index ["item_id"], name: "index_home_page_section_products_on_item_id"
    t.index ["position"], name: "index_home_page_section_products_on_position"
  end

  create_table "home_page_section_settings", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "key"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_home_page_section_settings_on_home_page_section_id"
  end

  create_table "home_page_section_side_banners", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "title"
    t.string "subtitle"
    t.text "description"
    t.string "cta_text"
    t.string "cta_link"
    t.string "bg_color", default: "#f3de6d"
    t.string "text_color", default: "#ffffff"
    t.integer "position", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_home_page_section_side_banners_on_home_page_section_id"
    t.index ["is_active"], name: "index_home_page_section_side_banners_on_is_active"
    t.index ["position"], name: "index_home_page_section_side_banners_on_position"
  end

  create_table "home_page_sections", force: :cascade do |t|
    t.string "section_type"
    t.string "title"
    t.text "description"
    t.boolean "is_active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_attributes", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id", "name"], name: "index_item_attributes_on_item_id_and_name", unique: true
    t.index ["item_id"], name: "index_item_attributes_on_item_id"
  end

  create_table "item_variants", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "size"
    t.string "color"
    t.string "sku"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "stock_quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false, null: false
    t.decimal "sale_price", precision: 10, scale: 2
    t.index ["item_id", "is_default"], name: "index_item_variants_on_item_default"
    t.index ["item_id", "stock_quantity"], name: "index_item_variants_on_item_stock"
    t.index ["item_id"], name: "index_item_variants_on_item_id"
    t.index ["sku"], name: "index_item_variants_on_sku", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "product_sub_category_id"
    t.bigint "currency_id", null: false
    t.string "name"
    t.string "validation_status", default: "pending"
    t.integer "position"
    t.string "slug"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "delivery_category_id"
    t.integer "views_count", default: 0, null: false
    t.string "ai_enrichment_status", default: "pending"
    t.string "meta_title"
    t.text "meta_description"
    t.jsonb "ai_generated_fields", default: {}
    t.string "origin_country"
    t.boolean "is_on_sale", default: false, null: false
    t.datetime "sale_start_date"
    t.datetime "sale_end_date"
    t.decimal "sale_discount_percent", precision: 5, scale: 2
    t.decimal "average_rating", precision: 3, scale: 2
    t.integer "variants_count", default: 0, null: false
    t.text "keywords"
    t.boolean "cash_on_delivery_disabled", default: false, null: false
    t.text "allowed_payment_codes"
    t.index ["ai_enrichment_status"], name: "index_items_on_ai_enrichment_status"
    t.index ["average_rating"], name: "index_items_on_average_rating"
    t.index ["currency_id"], name: "index_items_on_currency_id"
    t.index ["delivery_category_id"], name: "index_items_on_delivery_category_id"
    t.index ["is_on_sale"], name: "index_items_on_is_on_sale"
    t.index ["origin_country"], name: "index_items_on_origin_country"
    t.index ["product_sub_category_id", "validation_status"], name: "index_items_on_subcategory_status"
    t.index ["product_sub_category_id"], name: "index_items_on_product_sub_category_id"
    t.index ["sale_end_date"], name: "index_items_on_sale_end_date"
    t.index ["shop_id", "validation_status", "is_on_sale"], name: "index_items_on_shop_status_sale"
    t.index ["shop_id"], name: "index_items_on_shop_id"
    t.index ["validation_status", "created_at"], name: "index_items_on_status_created"
    t.index ["variants_count"], name: "index_items_on_variants_count"
    t.index ["views_count"], name: "index_items_on_views_count"
  end

  create_table "local_shop_banners", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "name"
    t.string "slug"
    t.string "link"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["active"], name: "index_local_shop_banners_on_active"
    t.index ["home_page_section_id"], name: "index_local_shop_banners_on_home_page_section_id"
  end

  create_table "maintenance_notifications", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone_number", null: false
    t.string "country_code", null: false
    t.string "user_type", null: false
    t.datetime "notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_maintenance_notifications_on_email", unique: true
    t.index ["phone_number"], name: "index_maintenance_notifications_on_phone_number"
    t.index ["user_type"], name: "index_maintenance_notifications_on_user_type"
  end

  create_table "newsletter_subscribers", force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.boolean "subscribed", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscribers_on_email", unique: true
  end

  create_table "official_brand_banners", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "name"
    t.string "link"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_official_brand_banners_on_home_page_section_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "item_id", null: false
    t.bigint "shop_id", null: false
    t.decimal "unit_price"
    t.integer "quantity"
    t.decimal "total_price"
    t.string "delivery_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "item_variant_id"
    t.index ["item_id"], name: "index_order_items_on_item_id"
    t.index ["item_variant_id", "delivery_status"], name: "index_order_items_on_variant_status"
    t.index ["item_variant_id"], name: "index_order_items_on_item_variant_id"
    t.index ["order_id", "shop_id"], name: "index_order_items_on_order_shop"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["shop_id", "delivery_status", "created_at"], name: "index_order_items_on_shop_status_created"
    t.index ["shop_id"], name: "index_order_items_on_shop_id"
  end

  create_table "order_status_histories", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "status"
    t.text "note"
    t.string "changed_by_type"
    t.bigint "changed_by_id"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["changed_by_type", "changed_by_id"], name: "index_order_status_histories_on_changed_by"
    t.index ["created_at"], name: "index_order_status_histories_on_created_at"
    t.index ["order_id", "status"], name: "index_order_status_histories_on_order_and_status"
    t.index ["order_id"], name: "index_order_status_histories_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "delivery_zone_id", null: false
    t.bigint "delivery_slot_id", null: false
    t.string "status"
    t.decimal "total_amount"
    t.decimal "delivery_fee"
    t.decimal "final_amount"
    t.bigint "currency_id", null: false
    t.text "delivery_address"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.datetime "departure_date"
    t.datetime "estimated_arrival_date"
    t.index ["currency_id"], name: "index_orders_on_currency_id"
    t.index ["delivery_slot_id"], name: "index_orders_on_delivery_slot_id"
    t.index ["delivery_zone_id"], name: "index_orders_on_delivery_zone_id"
    t.index ["slug"], name: "index_orders_on_slug", unique: true
    t.index ["status", "created_at"], name: "index_orders_on_status_created"
    t.index ["user_id", "status", "created_at"], name: "index_orders_on_user_status_created"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "provider"
    t.string "method_type"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_payment_methods_on_code", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "payment_method_id", null: false
    t.string "transaction_id"
    t.integer "status"
    t.decimal "amount"
    t.datetime "paid_at"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "paydunya_token"
    t.string "paydunya_invoice_url"
    t.string "payment_type"
    t.jsonb "provider_response"
    t.string "withdraw_mode"
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["payment_method_id"], name: "index_payments_on_payment_method_id"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id", unique: true
  end

  create_table "payouts", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.bigint "currency_id"
    t.string "status"
    t.string "reference_number"
    t.datetime "paid_at"
    t.integer "payout_month"
    t.integer "payout_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_payouts_on_currency_id"
    t.index ["shop_id"], name: "index_payouts_on_shop_id"
  end

  create_table "pending_registrations", force: :cascade do |t|
    t.string "user_type", null: false
    t.string "email"
    t.string "phone_number"
    t.text "encrypted_data", null: false
    t.string "otp_code", null: false
    t.datetime "otp_expires_at", null: false
    t.datetime "verified_at"
    t.string "channel"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_pending_registrations_on_email"
    t.index ["otp_code"], name: "index_pending_registrations_on_otp_code"
    t.index ["phone_number"], name: "index_pending_registrations_on_phone_number"
    t.index ["user_type", "email"], name: "index_pending_reg_on_type_email"
    t.index ["user_type", "phone_number"], name: "index_pending_reg_on_type_phone"
  end

  create_table "plan_rules", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "rule_id", null: false
    t.jsonb "value"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id", "rule_id"], name: "index_plan_rules_on_plan_and_rule", unique: true
    t.index ["plan_id"], name: "index_plan_rules_on_plan_id"
    t.index ["rule_id"], name: "index_plan_rules_on_rule_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.text "description"
    t.boolean "is_custom", default: false, null: false
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "billing_period_months"
    t.index ["code"], name: "index_plans_on_code", unique: true
  end

  create_table "product_attribute_values", force: :cascade do |t|
    t.bigint "product_attribute_id", null: false
    t.string "value", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_attribute_id", "value"], name: "index_product_attr_values_on_attr_id_and_value", unique: true
    t.index ["product_attribute_id"], name: "index_product_attribute_values_on_product_attribute_id"
  end

  create_table "product_attributes", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_product_attributes_on_name", unique: true
  end

  create_table "product_categories", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["slug"], name: "index_product_categories_on_slug", unique: true
  end

  create_table "product_sub_categories", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.boolean "is_active", default: false
    t.bigint "product_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["product_category_id"], name: "index_product_sub_categories_on_product_category_id"
    t.index ["slug"], name: "index_product_sub_categories_on_slug", unique: true
  end

  create_table "promo_banners", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "title"
    t.string "cta_text"
    t.string "cta_link"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_promo_banners_on_home_page_section_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "item_id", null: false
    t.bigint "order_item_id"
    t.integer "rating", null: false
    t.text "comment"
    t.string "status", default: "pending", null: false
    t.integer "helpful_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_reviews_on_created_at"
    t.index ["item_id"], name: "index_reviews_on_item_id"
    t.index ["order_item_id"], name: "index_reviews_on_order_item_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["status"], name: "index_reviews_on_status"
    t.index ["user_id", "item_id"], name: "index_reviews_on_user_id_and_item_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "rules", force: :cascade do |t|
    t.string "code"
    t.text "description"
    t.string "rule_type"
    t.jsonb "default_value"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_rules_on_code", unique: true
  end

  create_table "secondary_banners", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.string "title"
    t.string "link"
    t.string "gradient_from"
    t.string "gradient_to"
    t.string "position_type"
    t.integer "position_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id"], name: "index_secondary_banners_on_home_page_section_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.boolean "is_active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "sessionable_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sessionable_type"
    t.index ["sessionable_type", "sessionable_id"], name: "index_sessions_on_sessionable_type_and_sessionable_id"
  end

  create_table "shop_add_ons", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "add_on_id", null: false
    t.integer "quantity"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["add_on_id"], name: "index_shop_add_ons_on_add_on_id"
    t.index ["shop_id"], name: "index_shop_add_ons_on_shop_id"
  end

  create_table "shop_banners", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.integer "position", default: 0
    t.string "title"
    t.string "cta_text"
    t.string "cta_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "position"], name: "index_shop_banners_on_shop_id_and_position"
    t.index ["shop_id"], name: "index_shop_banners_on_shop_id"
  end

  create_table "shop_colors", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.string "hex_code", limit: 7, null: false
    t.integer "position", default: 0, null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "name"], name: "index_shop_colors_on_shop_and_name_active", unique: true, where: "(archived_at IS NULL)"
    t.index ["shop_id", "position"], name: "index_shop_colors_on_shop_id_and_position"
    t.index ["shop_id"], name: "index_shop_colors_on_shop_id"
  end

  create_table "shop_contacts", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "country_code"
    t.string "phone_number"
    t.boolean "is_whatsapp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_shop_contacts_on_shop_id"
  end

  create_table "shop_legal_infos", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "legal_form"
    t.string "rc_number"
    t.string "ninea_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_shop_legal_infos_on_shop_id"
  end

  create_table "shop_page_header_slides", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "link"
    t.string "button_text"
    t.integer "position", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "position"], name: "index_shop_page_header_slides_on_shop_id_and_position"
    t.index ["shop_id"], name: "index_shop_page_header_slides_on_shop_id"
  end

  create_table "shop_page_headers", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "link"
    t.string "button_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_shop_page_headers_on_shop_id", unique: true
  end

  create_table "shop_page_section_categories", force: :cascade do |t|
    t.bigint "shop_page_section_id", null: false
    t.bigint "product_sub_category_id", null: false
    t.integer "position", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_shop_page_section_categories_on_position"
    t.index ["product_sub_category_id"], name: "index_shop_page_section_categories_on_product_sub_category_id"
    t.index ["shop_page_section_id", "product_sub_category_id"], name: "index_shop_page_section_cats_on_section_and_subcat", unique: true
    t.index ["shop_page_section_id"], name: "index_shop_page_section_categories_on_shop_page_section_id"
  end

  create_table "shop_page_section_products", force: :cascade do |t|
    t.bigint "shop_page_section_id", null: false
    t.bigint "item_id", null: false
    t.integer "position", default: 1, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_shop_page_section_products_on_item_id"
    t.index ["position"], name: "index_shop_page_section_products_on_position"
    t.index ["shop_page_section_id", "item_id"], name: "index_shop_page_section_products_on_section_and_item", unique: true
    t.index ["shop_page_section_id"], name: "index_shop_page_section_products_on_shop_page_section_id"
  end

  create_table "shop_page_sections", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.string "section_type", null: false
    t.string "title"
    t.text "description"
    t.integer "position", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "position"], name: "index_shop_page_sections_on_shop_id_and_position"
    t.index ["shop_id", "section_type"], name: "index_shop_page_sections_on_shop_id_and_section_type"
    t.index ["shop_id"], name: "index_shop_page_sections_on_shop_id"
  end

  create_table "shop_payment_methods", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "payment_method_id", null: false
    t.boolean "is_active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_method_id"], name: "index_shop_payment_methods_on_payment_method_id"
    t.index ["shop_id"], name: "index_shop_payment_methods_on_shop_id"
  end

  create_table "shop_rules", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "rule_id", null: false
    t.jsonb "value"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rule_id"], name: "index_shop_rules_on_rule_id"
    t.index ["shop_id", "rule_id"], name: "index_shop_rules_on_shop_and_rule", unique: true
    t.index ["shop_id"], name: "index_shop_rules_on_shop_id"
  end

  create_table "shop_sectors", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "sector_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sector_id"], name: "index_shop_sectors_on_sector_id"
    t.index ["shop_id"], name: "index_shop_sectors_on_shop_id"
  end

  create_table "shop_social_links", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "social_platform_id", null: false
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_shop_social_links_on_shop_id"
    t.index ["social_platform_id"], name: "index_shop_social_links_on_social_platform_id"
  end

  create_table "shop_spotlights", force: :cascade do |t|
    t.bigint "home_page_section_id", null: false
    t.bigint "shop_id", null: false
    t.text "slogan"
    t.integer "position", default: 1
    t.string "promo_title"
    t.string "promo_subtitle"
    t.string "item_ids", comment: "IDs des produits à afficher, séparés par virgules"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_page_section_id", "position"], name: "index_shop_spotlights_on_section_and_position"
    t.index ["home_page_section_id"], name: "index_shop_spotlights_on_home_page_section_id"
    t.index ["shop_id"], name: "index_shop_spotlights_on_shop_id"
  end

  create_table "shop_transactions", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "order_id"
    t.bigint "payout_id"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0"
    t.bigint "currency_id"
    t.string "transaction_type"
    t.string "description"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_shop_transactions_on_currency_id"
    t.index ["order_id"], name: "index_shop_transactions_on_order_id"
    t.index ["payout_id"], name: "index_shop_transactions_on_payout_id"
    t.index ["shop_id"], name: "index_shop_transactions_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "slug"
    t.string "name"
    t.string "address"
    t.text "description"
    t.string "primary_color"
    t.string "secondary_color"
    t.string "status"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "views_count", default: 0, null: false
    t.decimal "balance", precision: 10, scale: 2, default: "0.0"
    t.bigint "currency_id"
    t.string "shop_type", default: "local", null: false
    t.integer "items_count", default: 0, null: false
    t.integer "available_items_count", default: 0, null: false
    t.decimal "commission_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.index ["available_items_count"], name: "index_shops_on_available_items_count"
    t.index ["currency_id"], name: "index_shops_on_currency_id"
    t.index ["items_count"], name: "index_shops_on_items_count"
    t.index ["shop_type"], name: "index_shops_on_shop_type"
    t.index ["status", "shop_type", "created_at"], name: "index_shops_on_status_type_created"
    t.index ["vendor_id"], name: "index_shops_on_vendor_id"
    t.index ["views_count"], name: "index_shops_on_views_count"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "label"
    t.string "description"
    t.string "kind", default: "text", null: false
    t.text "value_fr"
    t.text "value_en"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "sms_messages", force: :cascade do |t|
    t.string "from"
    t.string "to", null: false
    t.text "body", null: false
    t.string "status", default: "pending", null: false
    t.string "sms_type"
    t.string "provider"
    t.jsonb "provider_response", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sms_messages_on_created_at"
    t.index ["provider"], name: "index_sms_messages_on_provider"
    t.index ["status"], name: "index_sms_messages_on_status"
    t.index ["to"], name: "index_sms_messages_on_to"
  end

  create_table "social_platforms", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "icon_class"
    t.boolean "is_active"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subscription_payments", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "plan_id", null: false
    t.bigint "payment_method_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.string "withdraw_mode", null: false
    t.string "payment_type", default: "PAR"
    t.string "paydunya_token"
    t.string "paydunya_invoice_url"
    t.string "transaction_id"
    t.datetime "paid_at"
    t.json "provider_response"
    t.text "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["paydunya_token"], name: "index_subscription_payments_on_paydunya_token"
    t.index ["payment_method_id"], name: "index_subscription_payments_on_payment_method_id"
    t.index ["plan_id"], name: "index_subscription_payments_on_plan_id"
    t.index ["shop_id"], name: "index_subscription_payments_on_shop_id"
    t.index ["transaction_id"], name: "index_subscription_payments_on_transaction_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "shop_id", null: false
    t.bigint "plan_id", null: false
    t.string "status"
    t.datetime "started_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["shop_id"], name: "index_subscriptions_on_shop_id"
  end

  create_table "user_verifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code", null: false
    t.string "channel", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.boolean "status", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_user_verifications_on_status"
    t.index ["user_id", "code"], name: "index_user_verifications_on_user_id_and_code"
    t.index ["user_id"], name: "index_user_verifications_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address"
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "country_code", default: "SN", null: false
    t.string "phone_number"
    t.integer "orders_count", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["orders_count"], name: "index_users_on_orders_count"
    t.index ["phone_number"], name: "index_users_on_phone_number_unique", unique: true
  end

  create_table "variant_attribute_values", force: :cascade do |t|
    t.bigint "item_variant_id", null: false
    t.bigint "attribute_value_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attribute_value_id"], name: "index_variant_attribute_values_on_attribute_value_id"
    t.index ["item_variant_id", "attribute_value_id"], name: "index_variant_attribute_values_unique", unique: true
    t.index ["item_variant_id"], name: "index_variant_attribute_values_on_item_variant_id"
  end

  create_table "vendor_verifications", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "code", null: false
    t.string "channel", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: false, null: false
    t.index ["status"], name: "index_vendor_verifications_on_status"
    t.index ["vendor_id", "code"], name: "index_vendor_verifications_on_vendor_id_and_code"
    t.index ["vendor_id"], name: "index_vendor_verifications_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "country_code"
    t.string "email"
    t.string "password_digest"
    t.string "password_confirmation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.index ["email"], name: "index_vendors_on_email_unique", unique: true
    t.index ["phone_number"], name: "index_vendors_on_phone_number_unique", unique: true
  end

  create_table "zone_slots", force: :cascade do |t|
    t.bigint "delivery_zone_id", null: false
    t.bigint "delivery_slot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_slot_id"], name: "index_zone_slots_on_delivery_slot_id"
    t.index ["delivery_zone_id"], name: "index_zone_slots_on_delivery_zone_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "delivery_zones"
  add_foreign_key "addresses", "users"
  add_foreign_key "ahoy_events", "items", on_delete: :nullify
  add_foreign_key "ahoy_events", "shops", on_delete: :nullify
  add_foreign_key "attribute_values", "item_attributes"
  add_foreign_key "attribute_values", "shop_colors"
  add_foreign_key "blog_posts", "blog_categories"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "item_variants"
  add_foreign_key "cart_items", "items"
  add_foreign_key "carts", "users"
  add_foreign_key "delivery_prices", "delivery_categories"
  add_foreign_key "delivery_prices", "delivery_zones"
  add_foreign_key "employee_shops", "employees"
  add_foreign_key "employee_shops", "shops"
  add_foreign_key "employees", "vendors"
  add_foreign_key "hero_slider_slides", "home_page_sections"
  add_foreign_key "home_page_section_categories", "home_page_sections"
  add_foreign_key "home_page_section_categories", "product_categories"
  add_foreign_key "home_page_section_categories", "product_sub_categories"
  add_foreign_key "home_page_section_group_items", "home_page_section_groups"
  add_foreign_key "home_page_section_groups", "home_page_sections"
  add_foreign_key "home_page_section_items", "home_page_sections"
  add_foreign_key "home_page_section_products", "home_page_sections"
  add_foreign_key "home_page_section_products", "items"
  add_foreign_key "home_page_section_settings", "home_page_sections"
  add_foreign_key "home_page_section_side_banners", "home_page_sections"
  add_foreign_key "item_attributes", "items"
  add_foreign_key "item_variants", "items"
  add_foreign_key "items", "currencies"
  add_foreign_key "items", "delivery_categories"
  add_foreign_key "items", "product_sub_categories"
  add_foreign_key "items", "shops"
  add_foreign_key "local_shop_banners", "home_page_sections"
  add_foreign_key "official_brand_banners", "home_page_sections"
  add_foreign_key "order_items", "item_variants"
  add_foreign_key "order_items", "items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "shops"
  add_foreign_key "order_status_histories", "orders"
  add_foreign_key "orders", "currencies"
  add_foreign_key "orders", "delivery_slots"
  add_foreign_key "orders", "delivery_zones"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "orders"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payouts", "currencies"
  add_foreign_key "payouts", "shops"
  add_foreign_key "plan_rules", "plans"
  add_foreign_key "plan_rules", "rules"
  add_foreign_key "product_attribute_values", "product_attributes"
  add_foreign_key "product_sub_categories", "product_categories"
  add_foreign_key "promo_banners", "home_page_sections"
  add_foreign_key "reviews", "items"
  add_foreign_key "reviews", "order_items"
  add_foreign_key "reviews", "users"
  add_foreign_key "secondary_banners", "home_page_sections"
  add_foreign_key "shop_add_ons", "add_ons"
  add_foreign_key "shop_add_ons", "shops"
  add_foreign_key "shop_banners", "shops"
  add_foreign_key "shop_colors", "shops"
  add_foreign_key "shop_contacts", "shops"
  add_foreign_key "shop_legal_infos", "shops"
  add_foreign_key "shop_page_header_slides", "shops"
  add_foreign_key "shop_page_headers", "shops"
  add_foreign_key "shop_page_section_categories", "product_sub_categories"
  add_foreign_key "shop_page_section_categories", "shop_page_sections"
  add_foreign_key "shop_page_section_products", "items"
  add_foreign_key "shop_page_section_products", "shop_page_sections"
  add_foreign_key "shop_page_sections", "shops"
  add_foreign_key "shop_payment_methods", "payment_methods"
  add_foreign_key "shop_payment_methods", "shops"
  add_foreign_key "shop_rules", "rules"
  add_foreign_key "shop_rules", "shops"
  add_foreign_key "shop_sectors", "sectors"
  add_foreign_key "shop_sectors", "shops"
  add_foreign_key "shop_social_links", "shops"
  add_foreign_key "shop_social_links", "social_platforms"
  add_foreign_key "shop_spotlights", "home_page_sections"
  add_foreign_key "shop_spotlights", "shops"
  add_foreign_key "shop_transactions", "currencies"
  add_foreign_key "shop_transactions", "orders", on_delete: :nullify
  add_foreign_key "shop_transactions", "payouts", on_delete: :nullify
  add_foreign_key "shop_transactions", "shops"
  add_foreign_key "shops", "currencies"
  add_foreign_key "shops", "vendors"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subscription_payments", "payment_methods"
  add_foreign_key "subscription_payments", "plans"
  add_foreign_key "subscription_payments", "shops"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "shops"
  add_foreign_key "user_verifications", "users"
  add_foreign_key "variant_attribute_values", "attribute_values"
  add_foreign_key "variant_attribute_values", "item_variants"
  add_foreign_key "vendor_verifications", "vendors"
  add_foreign_key "zone_slots", "delivery_slots"
  add_foreign_key "zone_slots", "delivery_zones"
end
