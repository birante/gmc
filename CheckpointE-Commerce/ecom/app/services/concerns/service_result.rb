# frozen_string_literal: true

module ServiceResult
  # Helper pour créer des Result Structs de manière cohérente
  # Utilisation:
  #   Result = ServiceResult.build(:success?, :item, :errors)
  def self.build(*attributes, keyword_init: false)
    Struct.new(*attributes, keyword_init: keyword_init)
  end
end
