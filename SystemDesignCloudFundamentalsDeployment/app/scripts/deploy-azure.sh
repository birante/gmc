#!/usr/bin/env bash
# deploy-azure.sh — one-shot Azure App Service deployment.
#
# What it does:
#   1) creates a resource group, app service plan, and web app
#   2) sets MONGO_URI (and other env vars) on App Service — encrypted at rest
#   3) enables Local Git deployment on the web app
#   4) prints the URL + the Git remote to push to
#
# You run it. The MongoDB URI is read interactively (hidden input) so it
# never lands in a file or in your shell history. Nothing is committed.

set -euo pipefail

# ---------- inputs (edit APP_NAME to be globally unique) ---------------
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-mern-birante-ne}"
LOCATION="${LOCATION:-northeurope}"      # westeurope was at capacity for this subscription
PLAN_NAME="${PLAN_NAME:-plan-mern-birante}"
APP_NAME="${APP_NAME:-mern-birante-$(od -An -N2 -i /dev/urandom | tr -d ' ')}"   # random suffix to stay unique
SKU="${SKU:-F1}"                          # F1 (Free) or B1 (Basic ~$13/mo)
RUNTIME="${RUNTIME:-NODE:20-lts}"

echo "==> planned resources"
echo "    resource group : $RESOURCE_GROUP"
echo "    location       : $LOCATION"
echo "    plan           : $PLAN_NAME  (sku=$SKU)"
echo "    app            : $APP_NAME   (-> https://$APP_NAME.azurewebsites.net)"
echo "    runtime        : $RUNTIME"
echo
read -rp "Proceed? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || { echo "aborted."; exit 0; }

# ---------- login ------------------------------------------------------
if ! az account show > /dev/null 2>&1; then
  echo "==> az login (opens a browser)"
  az login
fi
az account show --query "{subscription: name, id: id, user: user.name}" -o table

# ---------- Atlas URI (from env or from .env) --------------------------
# Resolution order:
#   1) $MONGO_URI already exported in this shell
#   2) ../.env  (the .env at the app/ root, relative to scripts/)
#   3) prompt (hidden input) as a last resort
if [[ -z "${MONGO_URI:-}" ]]; then
  DOTENV_FILE="$(dirname "$0")/../.env"
  if [[ -f "$DOTENV_FILE" ]]; then
    # Extract MONGO_URI from .env, strip the KEY=, strip surrounding quotes.
    MONGO_URI="$(grep -E '^MONGO_URI=' "$DOTENV_FILE" | sed 's/^MONGO_URI=//; s/^"//; s/"$//')"
    if [[ -n "$MONGO_URI" ]]; then
      echo "==> loaded MONGO_URI from $DOTENV_FILE (${#MONGO_URI} chars)"
    fi
  fi
fi
if [[ -z "${MONGO_URI:-}" ]]; then
  echo
  echo "==> No MONGO_URI in the environment or in ../.env. Paste it now (input is HIDDEN"
  echo "    — nothing will appear as you type/paste; Cmd+V then Enter)."
  read -rsp "MONGO_URI: " MONGO_URI
  echo
fi
[[ -n "$MONGO_URI" ]] || { echo "MONGO_URI empty, aborting." >&2; exit 1; }

# Sanity check — a real Atlas URI is over 100 chars. If we got 16 chars,
# the user probably pasted just a password and not the full URI.
if [[ "${#MONGO_URI}" -lt 60 ]]; then
  echo "MONGO_URI looks too short (${#MONGO_URI} chars)." >&2
  echo "A real Atlas URI is 100+ chars and starts with 'mongodb+srv://'." >&2
  echo "Aborting to avoid deploying a broken configuration." >&2
  exit 1
fi
if [[ "$MONGO_URI" == *"<YOUR_ROTATED_PASSWORD>"* ]]; then
  echo "MONGO_URI still contains the '<YOUR_ROTATED_PASSWORD>' placeholder." >&2
  echo "Edit .env and replace it with your real password first." >&2
  exit 1
fi
echo "==> URI received (length: ${#MONGO_URI} chars)"

# ---------- create resources ------------------------------------------
# Try a list of regions in order — Azure Free/Trial subscriptions often
# have 0 quota in the first region we try (`Total VMs: 0`). Iterate
# until one accepts the F1 plan, then commit to that region.
REGIONS=("$LOCATION" "northeurope" "westeurope" "uksouth" "francecentral" "eastus" "eastus2" "centralus" "southeastasia")
CHOSEN_REGION=""

for candidate in "${REGIONS[@]}"; do
  echo "==> trying region: $candidate"

  az group create -n "$RESOURCE_GROUP" -l "$candidate" > /dev/null 2>&1 || {
    echo "   (could not create RG in $candidate, moving on)"; continue;
  }

  if az appservice plan create -g "$RESOURCE_GROUP" -n "$PLAN_NAME" \
       --is-linux --sku "$SKU" > /tmp/asp-out.txt 2>&1; then
    echo "   plan created in $candidate"
    CHOSEN_REGION="$candidate"
    break
  fi

  err=$(cat /tmp/asp-out.txt)
  echo "   plan failed in $candidate — snippet:"
  echo "   $(echo "$err" | grep -E 'ERROR|Message|Current Limit' | head -3 | sed 's/^/     /')"
  # remove the group we just made so we don't leak empty groups everywhere
  az group delete -n "$RESOURCE_GROUP" --yes --no-wait > /dev/null 2>&1 || true
done

if [[ -z "$CHOSEN_REGION" ]]; then
  echo
  echo "==> Every region we tried refused the F1 plan (subscription quota = 0)."
  echo "    Options:"
  echo "      * Request a quota increase:"
  echo "        https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade"
  echo "        (subject: 'App Service quota', service: 'App Service')"
  echo "      * Try SKU=B1 (Basic, ~\$13/mo): SKU=B1 ./scripts/deploy-azure.sh"
  echo "      * Check accepted regions for your subscription:"
  echo "        az provider show -n Microsoft.Web --query 'resourceTypes[?resourceType==\`serverfarms\`].locations' -o table"
  exit 1
fi

LOCATION="$CHOSEN_REGION"
echo "==> using region: $LOCATION"

echo "==> web app ($RUNTIME)"
az webapp create -g "$RESOURCE_GROUP" -p "$PLAN_NAME" -n "$APP_NAME" \
    --runtime "$RUNTIME" > /dev/null

echo "==> app settings (Kudu build ON, NODE_ENV=production, MONGO_URI)"
az webapp config appsettings set -g "$RESOURCE_GROUP" -n "$APP_NAME" \
    --settings \
        NODE_ENV=production \
        SCM_DO_BUILD_DURING_DEPLOYMENT=true \
        WEBSITE_NODE_DEFAULT_VERSION=~20 \
        MONGO_URI="$MONGO_URI" \
    -o none

echo "==> local-git deployment source"
GIT_URL=$(az webapp deployment source config-local-git \
    -g "$RESOURCE_GROUP" -n "$APP_NAME" --query url -o tsv)

echo
echo "============================================================"
echo " App URL         : https://$APP_NAME.azurewebsites.net"
echo " Git remote      : $GIT_URL"
echo "============================================================"
echo
echo " Next steps (from the app/ directory):"
echo
echo "   1) git init                                                    # if you haven't already"
echo "   2) git add . && git commit -m 'MERN app'"
echo "   3) git remote add azure \"$GIT_URL\""
echo "   4) git push azure main:master                                  # Azure's default branch is 'master'"
echo
echo " Live logs (in another terminal):"
echo "   az webapp log tail -g $RESOURCE_GROUP -n $APP_NAME"
