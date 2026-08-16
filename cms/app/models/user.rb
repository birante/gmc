class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles: subscriber < author < editor < admin
  enum :role, { subscriber: 0, author: 1, editor: 2, admin: 3 }, default: :subscriber

  has_many :posts,    foreign_key: :author_id, dependent: :nullify, inverse_of: :author
  has_many :comments, dependent: :destroy
  has_many :uploaded_media, class_name: "Medium", foreign_key: :uploaded_by_id, dependent: :nullify

  validates :first_name, :last_name, presence: true, length: { maximum: 50 }

  def full_name
    [first_name, last_name].compact.join(" ").presence || email
  end

  def can_edit?(post)
    admin? || editor? || post.author_id == id
  end

  def can_moderate?
    admin? || editor?
  end

  def self.ransackable_attributes(_ = nil); %w[id email first_name last_name role created_at]; end
  def self.ransackable_associations(_ = nil); %w[posts comments]; end
end
