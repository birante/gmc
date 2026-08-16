class BackfillShopStatusFromIntegerStrings < ActiveRecord::Migration[8.0]
  MAPPING = { "0" => "pending", "1" => "active", "2" => "suspended", "3" => "deactivate" }.freeze

  def up
    MAPPING.each do |old, new_value|
      execute ActiveRecord::Base.sanitize_sql_array(
        [ "UPDATE shops SET status = ? WHERE status = ?", new_value, old ]
      )
    end
  end

  def down
    MAPPING.each do |old, new_value|
      execute ActiveRecord::Base.sanitize_sql_array(
        [ "UPDATE shops SET status = ? WHERE status = ?", old, new_value ]
      )
    end
  end
end
