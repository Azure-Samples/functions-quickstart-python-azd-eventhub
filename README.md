<!--
---
name: Azure Functions Python Event Hubs Trigger using Azure Developer CLI
description: Python Azure Functions sample that streams generated news through Event Hubs, deployed to Flex Consumption with Azure Developer CLI (azd).
page_type: sample
products:
- azure-functions
- azure-event-hubs
- azure
- entra-id
urlFragment: functions-quickstart-python-azd-eventhub
languages:
- python
- bicep
- azdeveloper
---
-->

# Azure Functions with Event Hubs Trigger (Python)

A Python Azure Functions sample that generates news articles on a timer and processes them with an Event Hubs trigger. Deploy it to Azure Functions Flex Consumption with Azure Developer CLI (azd).

## Architecture

- **News Generator (Timer Trigger)**: Automatically generates realistic news articles every 10 seconds and streams them to Event Hubs
- **Azure Event Hubs**: Scalable messaging service that handles high-throughput news streaming with 32 partitions
- **News Processor (Event Hub Trigger)**: Processes articles as they arrive and logs engagement and sentiment scores
- **Azure Monitor**: Provides logging and metrics for function execution and news analytics

## Getting Started

### Prerequisites

- [Python 3.13](https://www.python.org/downloads/) or later
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools)
- [Azure Developer CLI (azd)](https://docs.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azurite](https://github.com/Azure/Azurite) for local development
- An Azure subscription

### Quickstart

1. **Clone this repository**

   ```bash
   git clone https://github.com/MadhuraBharadwaj-MSFT/functions-quickstart-python-azd-eventhub.git
   cd functions-quickstart-python-azd-eventhub
   ```

2. **Make sure to run this before calling azd to provision resources so azd can run scripts required to setup permissions**

   Mac/Linux:

   ```bash
   chmod +x ./infra/scripts/*.sh
   ```

   Windows:

   ```powershell
   Set-ExecutionPolicy RemoteSigned
   ```

3. **Configure VNet settings (optional)**

   You can choose whether to enable VNet integration:

   For simple deployment without VNet (public endpoints):

   ```bash
   azd env set VNET_ENABLED false
   ```

   For secure deployment with VNet (private endpoints):

   ```bash
   azd env set VNET_ENABLED true
   ```

   > **Note:** If you don't set `VNET_ENABLED`, the deployment will ask you to make an explicit choice.
   > Local development with VNet enabled requires access to the VNet.

4. **Provision Azure resources using azd**

   ```bash
   azd provision
   ```

   This will create all necessary Azure resources including:
   - Azure Event Hubs namespace and hub
   - Azure Function App (Flex Consumption)
   - Application Insights for monitoring
   - Storage Account for function app
   - Virtual Network with private endpoints (if `VNET_ENABLED=true`)
   - Other supporting resources
   - `local.settings.json` for local development with Azure Functions Core Tools, which should look like this:

   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "python",
       "EventHubConnection__fullyQualifiedNamespace": "your-eventhubs-namespace.servicebus.windows.net"
     }
   }
   ```

   The `azd` command automatically sets up the required connection strings and application settings.

5. **Start the function locally**

   ```bash
   func start
   ```

   Or use VS Code to run the project with the built-in Azure Functions extension by pressing F5.

6. **Test the function locally by watching the automatic news generation**

   The News Generator will automatically start creating articles every 10 seconds. You should see console output like:

   ```text
   [2024-11-10T10:30:15.123Z] HIGH-THROUGHPUT: Successfully generated 5 news articles in ~10 seconds
   [2024-11-10T10:30:15.145Z] ✅ Successfully processed article NEWS-20241110-A1B2C3D4 - 'Breaking: Major Discovery in Renewable Energy Technology' by Sarah Johnson
   [2024-11-10T10:30:15.147Z] 🔥 Viral article: NEWS-20241110-E5F6G7H8 - 8,547 views
   [2024-11-10T10:30:15.149Z] 📊 NEWS BATCH SUMMARY: 5 articles | Total Views: 18,432 | Avg Views: 3,686 | Avg Sentiment: 0.34
   ```

7. **Deploy to Azure**

   ```bash
   azd up
   ```

   This will build your function app and deploy it to Azure. The deployment process:
   - Checks for any bicep changes using `azd provision`
   - Packages the Python project using `azd package`
   - Publishes the function app using `azd deploy`
   - Updates application settings in Azure

8. **Test the deployed function by monitoring the logs in Azure Portal:**
   - Navigate to your Function App in the Azure Portal
   - Go to Functions → NewsGenerator or EventHubsTrigger
   - Check the Monitor tab to verify both functions are working
   - Use Application Insights Live Metrics to see real-time news processing

   In Application Insights **Logs**, query generation and processing traces:

   ```kusto
   traces
   | where timestamp > ago(1h)
   | where message contains "Successfully generated" or message contains "Successfully processed article"
   | project timestamp, message
   | order by timestamp desc
   ```

## Understanding the Code

- **NewsGenerator** runs every 10 seconds and sends 3-8 generated articles to the `news` event hub.
- **EventHubsTrigger** processes incoming articles and logs engagement and sentiment information.

The `EventHubConnection__fullyQualifiedNamespace` setting identifies the Event Hubs namespace and is configured by `azd`.

## Networking and VNet Integration

When `VNET_ENABLED=true`, the deployment:

- Integrates the function app with a VNet and creates separate private endpoint subnets for Event Hubs and Storage.
- Creates private endpoints for Event Hubs and Storage blob and table access, with VNet-linked private DNS zones.
- Disables public access to Event Hubs and Storage.

Local clients connecting to these services need network access to the VNet; adding a client IP rule does not bypass disabled public access. The `addclientip` scripts are not run automatically. If run manually, they can enable public Event Hubs access and replace existing IP rules; they do not restore the previous settings.

## Clean Up Resources

When you're done testing the sample, you can delete all Azure resources to avoid incurring charges:

```bash
azd down
```

This will:

- Delete all Azure resources created by `azd provision`
- Remove the resource group
- Clean up the local environment configuration

> **Note:** This action is irreversible. Make sure you no longer need the resources before running this command.

## Resources

- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [Azure Event Hubs Documentation](https://docs.microsoft.com/azure/event-hubs/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
