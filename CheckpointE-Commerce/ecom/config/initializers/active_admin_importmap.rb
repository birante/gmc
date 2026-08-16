# Étend l'importmap d'ActiveAdmin pour y câbler Lexxy (rich text editor)
# utilisé dans les formulaires admin (ex: BlogPost#content).
Rails.application.config.after_initialize do
  next unless defined?(ActiveAdmin) && ActiveAdmin.importmap

  ActiveAdmin.importmap.draw do
    pin "lexxy", to: "lexxy.js", preload: true
    pin "@rails/activestorage", to: "activestorage.esm.js", preload: true
    pin "@rails/actiontext", to: "actiontext.esm.js", preload: true
  end
end
