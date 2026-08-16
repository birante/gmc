class PostPolicy < ApplicationPolicy
  def index? = true
  def show?  = true
  def create? = user.present? && (user.author? || user.editor? || user.admin?)
  def new?    = create?
  def update? = user.present? && user.can_edit?(record)
  def edit?   = update?
  def destroy? = user.present? && (user.admin? || record.author_id == user.id)

  class Scope < Scope
    def resolve
      return scope.all if user&.can_moderate?
      user ? scope.where("status = 1 OR author_id = ?", user.id) : scope.for_public
    end
  end
end
