![UtilityInsighgts](./utility_insights.png)

# UtilityInsights
This project uses Azure OpenAI and Microsoft Fabric to analyze billing statements and extract electricity and gas expenses to generate insights.

# How to Run

### "Easy Button" Deployment
The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using bash. Run them line by line, as the az login portion is interactive:
```bash
git clone https://github.com/WeaveAnalytics/UtilityInsights.git
cd UtilityInsights
az login
bash deploy.sh
```

### Advanced Deployment:
If you already have all services needed, you can skip the automated deployment, and:
1. Upload the [documentextract.ipynb]([https://github.com/microsoft/needlr/tree/main/samples](https://github.com/WeaveAnalytics/UtilityInsights/blob/main/documentextract.ipynb)) notebook
2. Set a default Lakehouse for the Notebook
3. Update the Azure OpenAI URL and Key on the first cell of the notebook/
4. Upload some sample bills and run the notebook

# What's Deployed
- Azure OpenAI service
- Azure KeyVault to store secrets
- Azure Fabric Capacity to use in the process
