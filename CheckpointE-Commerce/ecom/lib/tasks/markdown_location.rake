# frozen_string_literal: true

namespace :markdown do
  desc "Fail if Markdown files exist outside docs/ (allowlist: root README.md, .github)
"
  task :enforce do
    allowed_prefixes = [ "docs/", ".github/" ]
    allowed_files = [ "README.md" ]
    forbidden = Dir.glob("**/*.md", File::FNM_DOTMATCH).reject do |path|
      allowed_files.include?(path) ||
        allowed_prefixes.any? { |prefix| path.start_with?(prefix) } ||
        path.start_with?("node_modules/", "vendor/", "tmp/", "storage/")
    end

    if forbidden.any?
      puts "✖ Markdown files outside docs/:"
      forbidden.sort.each { |path| puts "  - #{path}" }
      abort "Move Markdown files into docs/ (or extend the allowlist)."
    else
      puts "✔ All Markdown files are located under docs/ (or allowlisted)."
    end
  end
end
