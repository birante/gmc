class CategoryPolicy < ApplicationPolicy
  def index? = true
  def show?  = true
  def create? = user&.can_moderate?
  def new?    = create?
  def update? = create?
  def edit?   = create?
  def destroy? = user&.admin?

  class Scope < Scope
    def resolve; scope.all; end
  end
end
