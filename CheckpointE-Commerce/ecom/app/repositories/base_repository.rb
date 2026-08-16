# frozen_string_literal: true

# Repository de base avec des méthodes communes pour tous les repositories
#
# Usage:
#   class OrderRepository < BaseRepository
#     def model_class
#       Order
#     end
#   end
#
#   repo = OrderRepository.new
#   order = repo.find(id)
#   order = repo.create(attributes)
#   repo.update(order, attributes)
#   repo.destroy(order)
class BaseRepository
  # Trouver un enregistrement par ID
  #
  # @param id [String, Integer] L'identifiant de l'enregistrement
  # @param includes [Array, nil] Associations à précharger (optionnel)
  # @return [ActiveRecord::Base, nil] L'enregistrement trouvé ou nil
  def find(id, includes: nil)
    scope = model_class
    scope = scope.includes(includes) if includes.present?
    scope.find_by(id: id)
  end

  # Trouver un enregistrement par slug (pour FriendlyId)
  #
  # @param slug [String] Le slug de l'enregistrement
  # @param includes [Array, nil] Associations à précharger (optionnel)
  # @return [ActiveRecord::Base, nil] L'enregistrement trouvé ou nil
  def find_by_slug(slug, includes: nil)
    scope = model_class
    scope = scope.includes(includes) if includes.present?
    scope.friendly.find_by(slug: slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Trouver un enregistrement par un attribut
  #
  # @param attributes [Hash] Attributs de recherche
  # @param includes [Array, nil] Associations à précharger (optionnel)
  # @return [ActiveRecord::Base, nil] L'enregistrement trouvé ou nil
  def find_by(attributes, includes: nil)
    scope = model_class
    scope = scope.includes(includes) if includes.present?
    scope.find_by(attributes)
  end

  # Créer un nouvel enregistrement
  #
  # @param attributes [Hash] Attributs pour créer l'enregistrement
  # @param save [Boolean] Si true, sauvegarde immédiatement (défaut: true)
  # @return [ActiveRecord::Base] L'enregistrement créé (peut être invalide si save: false)
  def create(attributes, save: true)
    record = model_class.new(attributes)
    record.save if save
    record
  end

  # Créer un nouvel enregistrement avec !
  #
  # @param attributes [Hash] Attributs pour créer l'enregistrement
  # @return [ActiveRecord::Base] L'enregistrement créé
  # @raise [ActiveRecord::RecordInvalid] Si l'enregistrement est invalide
  def create!(attributes)
    model_class.create!(attributes)
  end

  # Construire un nouvel enregistrement sans sauvegarder
  #
  # @param attributes [Hash] Attributs pour construire l'enregistrement
  # @return [ActiveRecord::Base] L'enregistrement non sauvegardé
  def build(attributes = {})
    model_class.new(attributes)
  end

  # Mettre à jour un enregistrement
  #
  # @param record [ActiveRecord::Base] L'enregistrement à mettre à jour
  # @param attributes [Hash] Attributs à mettre à jour
  # @return [Boolean] True si la mise à jour a réussi
  def update(record, attributes)
    record.update(attributes)
  end

  # Mettre à jour un enregistrement avec !
  #
  # @param record [ActiveRecord::Base] L'enregistrement à mettre à jour
  # @param attributes [Hash] Attributs à mettre à jour
  # @return [ActiveRecord::Base] L'enregistrement mis à jour
  # @raise [ActiveRecord::RecordInvalid] Si l'enregistrement est invalide
  def update!(record, attributes)
    record.update!(attributes)
    record
  end

  # Détruire un enregistrement
  #
  # @param record [ActiveRecord::Base] L'enregistrement à détruire
  # @return [Boolean] True si la destruction a réussi
  def destroy(record)
    record.destroy
  end

  # Détruire un enregistrement avec !
  #
  # @param record [ActiveRecord::Base] L'enregistrement à détruire
  # @return [ActiveRecord::Base] L'enregistrement détruit
  # @raise [ActiveRecord::RecordNotDestroyed] Si la destruction échoue
  def destroy!(record)
    record.destroy!
    record
  end

  # Compter les enregistrements
  #
  # @param conditions [Hash, nil] Conditions de comptage (optionnel)
  # @return [Integer] Le nombre d'enregistrements
  def count(conditions = nil)
    scope = model_class
    scope = scope.where(conditions) if conditions.present?
    scope.count
  end

  # Vérifier si un enregistrement existe
  #
  # @param conditions [Hash, String, Integer] Conditions de recherche
  # @return [Boolean] True si l'enregistrement existe
  def exists?(conditions)
    model_class.exists?(conditions)
  end

  protected

  # Classe du modèle à utiliser (doit être surchargée dans les sous-classes)
  #
  # @return [Class] La classe du modèle ActiveRecord
  def model_class
    raise NotImplementedError, "Les sous-classes doivent implémenter model_class"
  end
end
