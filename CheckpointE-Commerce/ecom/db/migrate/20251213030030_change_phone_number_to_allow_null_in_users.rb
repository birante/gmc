class ChangePhoneNumberToAllowNullInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :phone_number, true
  end
end
