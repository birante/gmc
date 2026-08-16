class SetDefaultFalseOnPlansIsCustom < ActiveRecord::Migration[8.0]
  def up
    Plan.where(is_custom: nil).update_all(is_custom: false)
    change_column_default :plans, :is_custom, from: nil, to: false
    change_column_null :plans, :is_custom, false
  end

  def down
    change_column_null :plans, :is_custom, true
    change_column_default :plans, :is_custom, from: false, to: nil
  end
end
