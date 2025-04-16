#!/bin/bash
# Random prefix
randomnbr=$(printf "%06d" $((RANDOM % 1000000)))

# Define variables
resource_group="myResourceGroup${randomnbr}"
location="eastus"
account_name="myOpenAIAccount${randomnbr}"
deployment_name="gpt-4o-deployment${randomnbr}"
keyvault_name="myKeyVaultAccount${randomnbr}"
fabric_capacity_name="myfabriccapacity${randomnbr}"
fabric_capacity_sku="F64"

# Create resource group
az group create --name $resource_group --location $location

# Create Azure OpenAI Service
az cognitiveservices account create --name $account_name --resource-group $resource_group --kind OpenAI --sku S0 --location $location

# Deploy GPT-4o model
az cognitiveservices account deployment create --resource-group $resource_group --name $account_name --model-name gpt-4o --model-version 2024-11-20 --model-format OpenAI --sku GlobalStandard --deployment-name $deployment_name --sku-capacity 100

# Retrieve endpoint URL and API key
#endpoint_url=$(az cognitiveservices account show --name $account_name --resource-group $resource_group --query "properties.endpoint" --output tsv)
endpoint_url="https://${location}.api.cognitive.microsoft.com/openai/deployments/${deployment_name}/chat/completions?api-version=2025-01-01-preview"
api_key=$(az cognitiveservices account keys list --name $account_name --resource-group $resource_group --query "key1" --output tsv)

# Create the Azure KeyVault
current_user_name=$(az ad signed-in-user show --query userPrincipalName -o tsv)
current_user_id=$(az ad signed-in-user show --query id -o tsv)
az keyvault create --name $keyvault_name --resource-group $resource_group --location $location
az role assignment create --assignee ${current_user_id} --role "Key Vault Secrets Officer" --scope $(az keyvault show --name ${keyvault_name} --resource-group ${resource_group} --query id -o tsv)
sleep 10
az keyvault secret set --vault-name $keyvault_name --name gpt4ourl --value $endpoint_url
az keyvault secret set --vault-name $keyvault_name --name gpt4okey --value $api_key

# Create the Azure Capacity
az fabric capacity create --resource-group $resource_group --capacity-name $fabric_capacity_name --sku "{name:${fabric_capacity_sku},tier:Fabric}" --location $location --administration "{members:[${current_user_name}]}"

# Export needed variables
export FABRIC_CAPACITY=$fabric_capacity_name
export KEY_VAULT_NAME=$keyvault_name
export AZURE_OPENAI_URL=$endpoint_url
export AZURE_OPENAI_KEY=api_key
echo "Fabric Capacity: $fabric_capacity_name"
echo "Key Vault: $keyvault_name"
echo "Azure OpenAI Endpoint URL: $endpoint_url"
echo "Azure OpenAI API Key: $api_key"

# Update Notebook file
sed -i "s/REPLACE_GPT4V_KEY/$endpoint_url/g" ./documentextract.ipynb
sed -i "s/REPLACE_GPT4V_ENDPOINT/$endpoint_url/g" ./documentextract.ipynb

pip install needlr --user
python ./test.py
