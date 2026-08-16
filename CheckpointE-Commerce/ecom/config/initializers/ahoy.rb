# frozen_string_literal: true

# Documentation: https://github.com/ankane/ahoy

class Ahoy::Store < Ahoy::DatabaseStore
  # Track additional visit data
  def track_visit(data)
    # 🚀 Skip tracking for ActiveStorage/asset requests
    # `request` est une méthode du store (pas data[:request] qui serait toujours nil)
    return if request && !should_track_request?(request)

    super(data)
  end

  # Track additional event data — extrait shop_id et item_id dans les colonnes dédiées
  def track_event(data)
    props = data[:properties] || {}
    data[:shop_id] = props[:shop_id].presence || props["shop_id"]
    data[:item_id] = props[:item_id].presence || props["item_id"]
    super(data)
  end

  private

  # 🚀 Skip tracking for static asset/media requests
  def should_track_request?(req)
    path = req.path.to_s
    !path.start_with?("/rails/active_storage/", "/rails/assets/", "/assets/")
  end

  # Optionnel: Désactiver le linking automatique user/visit pour RGPD strict
  # def authenticate(data)
  #   # Ne fait rien = pas de linking automatique
  # end
end

# ========================================
# CONFIGURATION GÉNÉRALE
# ========================================

# API pour tracking JavaScript (Ahoy.js)
Ahoy.api = false  # false = server-side uniquement

# Ne pas tracker les bots
Ahoy.track_bots = false

# Mode silencieux (pas de logs verbeux)
Ahoy.quiet = true

# ========================================
# RGPD / PRIVACY
# ========================================

# Masquer les IPs (RGPD compliance)
# Pour IPv4: 8.8.4.4 devient 8.8.4.0
# Pour IPv6: derniers 80 bits mis à zéro
Ahoy.mask_ips = true

# Cookies: :none pour anonymity sets (RGPD friendly)
# Au lieu de cookies, groupe les visiteurs par IP masqué + user agent
Ahoy.cookies = :none

# ========================================
# DURÉES
# ========================================

# Durée d'une visite (nouvelle visite après cette période d'inactivité)
Ahoy.visit_duration = 4.hours

# Durée du visitor token (si cookies activés)
# Ahoy.visitor_duration = 2.years

# ========================================
# GÉOLOCALISATION
# ========================================

# GeoCoding via IP (nécessite le gem 'geocoder')
# Active la détection de: country, region, city, latitude, longitude
Ahoy.geocode = true  # true pour activer

# Si vous utilisez un CDN/proxy avec headers de géolocalisation
# class Ahoy::Store < Ahoy::DatabaseStore
#   def track_visit(data)
#     data[:country] = request.headers["CF-IPCountry"]  # Cloudflare
#     data[:region] = request.headers["CloudFront-Viewer-Country-Region"]  # CloudFront
#     super(data)
#   end
# end

# ========================================
# AUTRES OPTIONS
# ========================================

# Domaine des cookies (si Ahoy.cookies != :none)
# Ahoy.cookie_domain = :all  # Pour partager entre sous-domaines

# Token generator personnalisé
# Ahoy.token_generator = -> { SecureRandom.uuid }

# User agent parser (device_detector par défaut)
# Ahoy.user_agent_parser = :device_detector

# ========================================
# NETTOYAGE DES DONNÉES
# ========================================

# Pensez à nettoyer régulièrement les anciennes données:
#
# Ahoy::Visit.where("started_at < ?", 2.years.ago).find_in_batches do |visits|
#   visit_ids = visits.map(&:id)
#   Ahoy::Event.where(visit_id: visit_ids).delete_all
#   Ahoy::Visit.where(id: visit_ids).delete_all
# end
#
# Ou utilisez une tâche Rake/Cron
