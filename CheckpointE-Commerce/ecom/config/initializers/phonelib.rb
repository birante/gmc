# Configuration pour phonelib
# Définir le pays par défaut pour la validation des numéros de téléphone

Phonelib.default_country = "SN" # Code ISO du Sénégal

# Configuration pour les types de numéros acceptés
Phonelib.extension_separator = " ext. "

# Configuration pour les formats de numéros
Phonelib.extension_separate_symbols = %w[; ,]

# Configuration pour les pays africains prioritaires
# Note: override_phone_data doit être un chemin vers un fichier, pas un Hash
# Pour l'instant, on utilise la configuration par défaut de phonelib
# qui supporte déjà le Sénégal correctement
