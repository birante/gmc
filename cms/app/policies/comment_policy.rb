class CommentPolicy < ApplicationPolicy
  def create? = user.present?
  def moderate? = user&.can_moderate?
  def destroy? = user&.admin? || (user && record.user_id == user.id)

  class Scope < Scope
    def resolve
      return scope.all if user&.can_moderate?
      scope.approved.or(user ? scope.where(user_id: user.id) : scope.none)
    end
  end
end
