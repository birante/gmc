# frozen_string_literal: true

class RemoveIsActiveFromItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :items, :is_active, :boolean
  end
end
