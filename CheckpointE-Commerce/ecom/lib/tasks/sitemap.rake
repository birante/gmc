# Génère le sitemap en même temps que la précompilation des assets.
#
# Conséquence : `public/sitemap.xml.gz` est présent dans l'image Docker
# (et donc servi par Kamal proxy), ce qui permet à Google de découvrir
# toutes les URLs au lieu de tomber sur un 404 (ce qui était le cas
# auparavant et expliquait pourquoi quasiment aucune page n'était
# indexée).
#
# Le job récurrent dans config/recurring.yml prend le relais ensuite
# pour rafraîchir le sitemap quotidiennement entre deux deploys.

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do
    if Rake::Task.task_defined?("sitemap:create")
      begin
        Rake::Task["sitemap:create"].invoke
      rescue StandardError => e
        warn "[sitemap] generation skipped: #{e.class}: #{e.message}"
      end
    end
  end
end
