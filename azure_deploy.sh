#!/bin/bash
# Load parameters file
source ./parameters.sh
# Random prefix
suffix=$(printf "%06d" $((RANDOM % 1000000)))

# Define variables
resource_group="${RESOURCE_GROUP}${suffix}"
location=$LOCATION
account_name="${ACCOUNT_NAME}${suffix}"
deployment_name="${DEPLOYMENT_NAME}${suffix}"
keyvault_name="${KEYVAULT_NAME}${suffix}"
app_name="${APP_NAME}${suffix}"
fabric_capacity_name="${FABRIC_CAPACITY_NAME}${suffix}"
fabric_capacity_sku=$FABRIC_CAPACITY_SKU
fabric_workspace="${FABRIC_WORKSPACE}${suffix}"

# Show only errors
az config set core.only_show_errors=true >> output.log

# If Resource Gorup already exists, use it. Otherwise create a new one using suffix
if [ $(az group exists --name $RESOURCE_GROUP) = false ]; then
    echo "Resource Group does not exist. Creating the resource group ${resource_group} ..."
    az group create --name $resource_group --location $location >> output.log
else
    echo "Resource group ${RESOURCE_GROUP} already exists. It will be used on this deployment."
    resource_group=$RESOURCE_GROUP
fi

# Check if the Azure OpenAI service exists
SERVICE_EXISTS=$(az resource list --resource-type "Microsoft.CognitiveServices/accounts" --query "[?name=='$ACCOUNT_NAME']" --output tsv)
if [ -z "$SERVICE_EXISTS" ]; then
    echo "Azure OpenAI account does not exist. Creating Azure OpenAI account ${account_name} ..."
    az cognitiveservices account create --name $account_name --resource-group $resource_group --kind OpenAI --sku S0 --location $location >> output.log
else
    echo "Azure OpenAI account ${ACCOUNT_NAME} already exists. It will be used on this deployment."
    account_name=$ACCOUNT_NAME
fi

# Check if the Azure OpenAI model deployment exists
DEPLOYMENT_EXISTS=$(az cognitiveservices account deployment list -n $account_name -g $resource_group --query "[?name=='$DEPLOYMENT_NAME']" --output tsv)
#DEPLOYMENT_EXISTS=$(az cognitiveservices account list-models -n $account_name -g $resource_group)
#DEPLOYMENT_EXISTS=$(az openai deployment list --resource-group $resource_group --resource-name $account_name --query "[?name=='$DEPLOYMENT_NAME']" --output tsv)
if [ -z "$DEPLOYMENT_EXISTS" ]; then
    echo "Model deployment does not exist. Deploying model ${deployment_name} ..."
    az cognitiveservices account deployment create --resource-group $resource_group --name $account_name --model-name gpt-4o --model-version 2024-11-20 --model-format OpenAI --sku GlobalStandard --deployment-name $deployment_name --sku-capacity 100 >> output.log
else
    echo "Model deployment already exists. It will be used on this deployment"
    deployment_name=$DEPLOYMENT_NAME
fi
# Retrieve endpoint URL and API key
#endpoint_url=$(az cognitiveservices account show --name $account_name --resource-group $resource_group --query "properties.endpoint" --output tsv)
endpoint_url="https://${location}.api.cognitive.microsoft.com/openai/deployments/${deployment_name}/chat/completions?api-version=2025-01-01-preview"
api_key=$(az cognitiveservices account keys list --name $account_name --resource-group $resource_group --query "key1" --output tsv)

# Check if the Key Vault exists
KEYVAULT_EXISTS=$(az keyvault list --query "[?name=='$KEYVAULT_NAME']" --output tsv)
if [ -z "$KEYVAULT_EXISTS" ]; then
    echo "Key Vault does not exist. Creating the Key Vault ${keyvault_name} ..."
    current_user_name=$(az ad signed-in-user show --query userPrincipalName -o tsv)
    current_user_id=$(az ad signed-in-user show --query id -o tsv)
    az keyvault create --name $keyvault_name --resource-group $resource_group --location $location >> output.log
    az role assignment create --assignee ${current_user_id} --role "Key Vault Secrets Officer" --scope $(az keyvault show --name ${keyvault_name} --resource-group ${resource_group} --query id -o tsv) >> output.log
    sleep 10
else
    echo "Key Vault already exists. It will be used on this deployment"
    keyvault_name=$KEYVAULT_NAME
fi

# Check if gpt4ourl secret exists
SECRET_EXISTS=$(az keyvault secret list --vault-name $keyvault_name --query "[?name=='gpt4ourl']" --output tsv)
if [ -z "$SECRET_EXISTS" ]; then
    echo "Secret does not exist. Creating secrets gpt4ourl ..."
    az keyvault secret set --vault-name $keyvault_name --name gpt4ourl --value $endpoint_url >> output.log
    az keyvault secret set --vault-name $keyvault_name --name gpt4okey --value $api_key >> output.log
else
    echo "Secrets already exists."
fi

APP_EXISTS=$(az ad app list --display-name $APP_NAME --query "[?displayName=='$APP_NAME']" --output tsv)
if [ -z "$APP_EXISTS" ]; then
    echo "App registration does not exist. Creating the app registration ${app_name}..."
    az ad app create --display-name ${app_name} >> output.log
    app_id=$(az ad app list --query "[?displayName=='${app_name}'].appId" --output tsv)
    sleep 30
    az ad app permission add --id $app_id --api "00000009-0000-0000-c000-000000000000" --api-permissions 28379fa9-8596-4fd9-869e-cb60a93b5d84=Role >> output.log
    sleep 30
    az ad app permission admin-consent --id $app_id >> output.log
else
    echo "App registration already exists."
    app_name=$APP_NAME
fi

# Extract App Registration Tenant and Secret for next Configuration step
tomorrow_date=$(date -d "tomorrow" +"%Y-%m-%d")
tenant=$(az ad app credential reset --id $app_id --end-date $tomorrow_date --query "tenant" --output tsv)
secret=$(az ad app credential reset --id $app_id --end-date $tomorrow_date --query "password" --output tsv)

# Check if the Microsoft Fabric capacity exists
az extension add --name microsoft-fabric
CAPACITY_EXISTS=$(az fabric capacity list --query "[?name=='$FABRIC_CAPACITY_NAME']" --output tsv)
if [ -z "$CAPACITY_EXISTS" ]; then
    echo "Fabric capacity does not exist. Creating the capacity ${fabric_capacity_name} with ${fabric_capacity_sku} SKU ..."
    az fabric capacity create --resource-group $resource_group --capacity-name $fabric_capacity_name --sku "{name:${fabric_capacity_sku},tier:Fabric}" --location $location --administration "{members:[${current_user_name}]}" >> output.log
    sleep 5
else
    echo "Fabric capacity already exists."
    fabric_capacity_name=$FABRIC_CAPACITY_NAME
fi

# Export needed variables
export FABRIC_CAPACITY=$fabric_capacity_name
export FABRIC_WORKSPACE=$fabric_workspace
export KEY_VAULT_NAME=$keyvault_name
export AZURE_OPENAI_URL=$endpoint_url
export AZURE_OPENAI_KEY=$api_key
export APP_ID=$app_id
export APP_SECRET=$secret
echo "Make sure eveyone has Contributor access to the Fabric Capacity: $fabric_capacity_name"
echo "This access can be removed after deployment"

# Create Environment file used by needlr
cat <<EOT > .env
APP_ID=$app_id
APP_SECRET=$secret
TENANT_ID=$tenant
CAPACITY_NAME=$fabric_capacity_name
CURRENT_USER_ID=$current_user_id
FABRIC_WORKSPACE=$fabric_workspace
KEY_VAULT_NAME=$keyvault_name
EOT

echo ".env file has been created!"
