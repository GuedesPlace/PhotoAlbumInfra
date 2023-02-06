# PhotoAlbumInfra
IaC for the PhotoAlbum Application

## Prerequisites

You need a Bicep file to deploy. The file must be local.

You need Azure PowerShell and to be connected to Azure:

- **Install Azure PowerShell cmdlets on your local computer.** To deploy Bicep files, you need [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps) version **5.6.0 or later**. For more information, see [Get started with Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/get-started-azureps).
- **Install Bicep CLI.** Azure PowerShell doesn't automatically install the Bicep CLI. Instead, you must [manually install the Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually).
- **Connect to Azure by using [Connect-AzAccount](https://learn.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount)**. If you have multiple Azure subscriptions, you might also need to run [Set-AzContext](https://learn.microsoft.com/en-us/powershell/module/Az.Accounts/Set-AzContext). For more information, see [Use multiple Azure subscriptions](https://learn.microsoft.com/en-us/powershell/azure/manage-subscriptions-azureps).

If you don't have PowerShell installed, you can use Azure Cloud Shell. For more information, see [Deploy Bicep files from Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cloud-shell?tabs=azure-cli).

## Installation prcedure

The installation of the PhotoAlbumInfra in Azure has to be done 5 Steps:

1. Deploy the infrastructure
2. Register the Enpoints in your DNS
3. Connect the DNS to the Infracture
4. Register the Application in your B2C Azure Directory
5. Update API Endpoint with the Application Registry Details

### Deploy the infrastructure
- Start a powershell command window and login to azure with Connect-AzAccount
- Change to this directory
- If you dont have defined a resource group, add the resource group
  ```azurepowershell
  New-AzResourceGroup -Name <resource-group-name> -Location <location-name>
- Start the deployment with the following command
  ```azurepowershell
  New-AzResourceGroupDeployment -ResourceGroupName <resource-group-name> -TemplateFile main.bicep
Please note the output values for
- html5ClientUrl
- apiUrl
- apiVerificationId
This values are needed for the next step.
### Register the Endpoints in your DNS
You have to register 2 Endpoint for your application. One is for the HTML5 Client and the other is for the API. They look normaly like this:
- HTML5 Client: photo.<yourdomain.com>
- API: photoapi.<yourdomain.com>


### Connect the DNS to the Infrastructure
- exec update_domain.bicep
- start SSL Registration