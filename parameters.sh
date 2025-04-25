#!/bin/bash
# Deployment Parameters (prefix)
# If RG already exists it will be used. 
RESOURCE_GROUP="UtilityInsightsRG"
LOCATION="eastus"
# If Azure OpenAI service already exists it will be used. 
ACCOUNT_NAME="utilityinsightsoai"
# If Azure OpenAI model is already deployed it will be used. 
DEPLOYMENT_NAME="utilityinsightsgpt4o"
# If Azure KeyVault is already deployed it will be used. 
KEYVAULT_NAME="utilityinsightskv"
# If Entra App Registration is already deployed it will be used. 
APP_NAME="utilityinsightsfapp"
# If Fabric Capacity is already deployed it will be used. 
FABRIC_CAPACITY_NAME="utilityinsightsfc"
FABRIC_CAPACITY_SKU="F64"
# If Fabric Workspace Name is already deployed it will be used. 
FABRIC_WORKSPACE="Utility Insights"

