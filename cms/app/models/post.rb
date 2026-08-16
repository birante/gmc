class Post < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: %i[slugged history]

  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  belongs_to :author, class_name: "User", optional: true
  belongs_to :category, optional: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :comments, dependent: :destroy

  validates :title,   presence: true, length: { maximum: 255 }
  validates :content, presence: true

  before_save :compute_reading_time, :ensure_published_at

  scope :recent,     -> { order(published_at: :desc, created_at: :desc) }
  scope :featured,   -> { where(is_featured: true) }
  scope :for_public, -> { published.where("published_at IS NULL OR published_at <= ?", Time.current) }

  def self.ransackable_attributes(_ = nil)
    %w[title slug status is_featured published_at created_at]
  end
  def self.ransackable_associations(_ = nil)
    %w[author category tags]
  end

  def excerpt_or_snippet(length: 200)
    return excerpt if excerpt.present?
    text = ActionController::Base.helpers.strip_tags(content.to_s)
    text.length > length ? "#{text.first(length)}…" : text
  end

  private

  def compute_reading_time
    return if content.blank?
    words = ActionController::Base.helpers.strip_tags(content).split(/\s+/).size
    self.reading_time = [(words / 200.0).ceil, 1].max
  end

  def ensure_published_at
    self.published_at ||= Time.current if published? && published_at.blank?
  end
end
