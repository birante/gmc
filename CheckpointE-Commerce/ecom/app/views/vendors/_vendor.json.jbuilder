json.extract! vendor, :id, :first_name, :last_name, :phone_number, :country_code, :email, :password_digest, :password_confirmation, :status, :created_at, :updated_at
json.url vendor_url(vendor, format: :json)
