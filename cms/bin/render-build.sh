#!/usr/bin/env bash
# Render's build hook — install gems, precompile assets, migrate DB.
set -o errexit
set -o pipefail
set -o nounset

echo "==> bundle install"
bundle install

echo "==> asset precompile"
bundle exec rails assets:precompile
bundle exec rails assets:clean

echo "==> db migrate"
bundle exec rails db:migrate

echo "==> seed (idempotent)"
bundle exec rails db:seed
