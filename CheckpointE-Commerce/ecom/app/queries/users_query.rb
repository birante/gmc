# frozen_string_literal: true

# Query pour lire les utilisateurs
#
# Usage:
#   query = UsersQuery.new
#   user = query.find_by_id(id)
class UsersQuery
  def self.find_by_id(id)
    User.find_by(id: id)
  end
end
