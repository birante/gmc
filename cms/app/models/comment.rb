class Comment < ApplicationRecord
  enum :status, { pending: 0, approved: 1, spam: 2, trash: 3 }, default: :pending

  belongs_to :post
  belongs_to :user, optional: true
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :content, presence: true, length: { maximum: 4000 }

  scope :recent, -> { order(created_at: :desc) }

  def self.ransackable_attributes(_ = nil); %w[status content created_at]; end
end
