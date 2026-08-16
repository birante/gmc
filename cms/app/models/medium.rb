class Medium < ApplicationRecord
  self.table_name = "media"

  belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by_id, optional: true

  has_one_attached :file

  validates :filename, presence: true

  def self.ransackable_attributes(_ = nil); %w[filename mime_type file_type created_at]; end
end
