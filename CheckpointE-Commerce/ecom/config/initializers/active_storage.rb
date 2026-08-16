# Ajoute un préfixe aux clés Active Storage, en évitant les erreurs
# pendant assets:precompile où ActiveStorage peut ne pas être chargé.

Rails.application.config.to_prepare do
  begin
    require "active_storage/blob"
    ActiveStorage::Blob.singleton_class.class_eval do
      def generate_unique_secure_token
        "aa/#{SecureRandom.base58(24)}"
      end
    end
  rescue LoadError, NameError
    # Si ActiveStorage n'est pas chargé à ce moment, on ignore silencieusement;
    # le bloc to_prepare sera réévalué quand les classes seront prêtes.
  end
end
