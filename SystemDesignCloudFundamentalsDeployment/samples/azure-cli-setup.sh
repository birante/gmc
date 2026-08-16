#!/usr/bin/env bash
# azure-cli-setup.sh — the Portal walk-through as a shell script.
# Requires the Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
#
# Run: bash samples/azure-cli-setup.sh

set -euo pipefail

# ---- adjust these ----------------------------------------------------------
RESOURCE_GROUP="rg-mern-prod"
LOCATION="westeurope"                # keep in the same region as your Atlas cluster
APP_SERVICE_PLAN="plan-mern-prod"
APP_NAME="my-mern-app"               # must be globally unique across azurewebsites.net
SKU="B1"                             # F1 (free), B1, S1, P1v3 …
NODE_RUNTIME="NODE:18-lts"

MONGO_URI="mongodb+srv://<user>:<password>@mern-prod.abcd.mongodb.net/mydb?retryWrites=true&w=majority"
JWT_SECRET="replace-with-a-long-random-string"

# ---- 1. login (opens a browser) --------------------------------------------
az login

# ---- 2. resource group -----------------------------------------------------
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# ---- 3. App Service Plan (the VM behind the app) ---------------------------
az appservice plan create \
    --name "$APP_SERVICE_PLAN" \
    --resource-group "$RESOURCE_GROUP" \
    --is-linux --sku "$SKU"

# ---- 4. Web App (the app itself) -------------------------------------------
az webapp create \
    --resource-group "$RESOURCE_GROUP" \
    --plan "$APP_SERVICE_PLAN" \
    --name "$APP_NAME" \
    --runtime "$NODE_RUNTIME"

# ---- 5. Environment variables ----------------------------------------------
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --settings \
        NODE_ENV=production \
        MONGO_URI="$MONGO_URI" \
        JWT_SECRET="$JWT_SECRET" \
        SCM_DO_BUILD_DURING_DEPLOYMENT=true

# ---- 6. Local Git deployment source ----------------------------------------
az webapp deployment source config-local-git \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME"

# The command prints a Git URL; add it as a remote and push:
#   git remote add azure <printed-url>
#   git push azure main

echo
echo "==> App URL: https://$APP_NAME.azurewebsites.net"
echo "==> Tail logs with: az webapp log tail -g $RESOURCE_GROUP -n $APP_NAME"
