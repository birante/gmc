class BlogPost < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  STATUSES = %w[draft published].freeze

  belongs_to :blog_category, optional: true
  has_one_attached :cover_image
  has_rich_text :content

  validates :title, presence: true
  validates :content, presence: true
  validates :status, inclusion: { in: STATUSES }

  before_save :set_published_at

  scope :published, -> { where(status: "published") }
  scope :recent,    -> { order(published_at: :desc, created_at: :desc) }
  scope :by_category, ->(slug) { joins(:blog_category).where(blog_categories: { slug: slug }) }

  def published?
    status == "published"
  end

  def reading_time_minutes
    words = content.to_plain_text.split(/\s+/).size
    [ (words / 200.0).ceil, 1 ].max
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "author_name", "blog_category_id", "created_at", "excerpt",
      "id", "published_at", "slug", "status", "title", "updated_at", "views_count" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "blog_category", "cover_image_attachment", "cover_image_blob", "rich_text_content" ]
  end

  private

  def set_published_at
    self.published_at ||= Time.current if status == "published"
  end
end
