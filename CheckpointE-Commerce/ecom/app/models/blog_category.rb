class BlogCategory < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :blog_posts, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "id", "name", "position", "slug", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "blog_posts" ]
  end
end
