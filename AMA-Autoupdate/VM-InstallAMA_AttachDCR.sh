#!/bin/bash

# Variables
vmName="Billm-Ubuntu-test"
resourceGroup="billmtestrg"
dcrName="DCR-USAE2-ANALYTICS-NP"
dcrId="/subscriptions/1f23c81c-b2c0-4a87-aa24-854ed990670b/resourcegroups/BillMTestRG/providers/microsoft.insights/datacollectionrules/DCR-USAE2-ANALYTICS-NP"
insightsDcrName="MSVMI-BillM-USAE2-Insights-Rule"
insightsDcrId="/subscriptions/1f23c81c-b2c0-4a87-aa24-854ed990670b/resourcegroups/BillMTestRG/providers/microsoft.insights/datacollectionrules/MSVMI-BillM-USAE2-Insights-Rule"
chTrackingInvName="ct-dcr-bash"
chTrackingInvId="/subscriptions/1f23c81c-b2c0-4a87-aa24-854ed990670b/resourcegroups/BillMTestRG/providers/microsoft.insights/datacollectionrules/ct-dcr-bash"
vmResourceId="/subscriptions/1f23c81c-b2c0-4a87-aa24-854ed990670b/resourceGroups/billmtestrg/providers/Microsoft.Compute/virtualMachines/Billm-Ubuntu-test"
logAnalyticsWorkspaceId="/subscriptions/1f23c81c-b2c0-4a87-aa24-854ed990670b/resourceGroups/billmtestrg/providers/Microsoft.OperationalInsights/workspaces/LAW-USAE2-ANALYTICS-NP"
logAnalyticsWorkspaceProdId="/subscriptions/1f23c81c-b2c0-4a87-aa24-854ed990670b/resourceGroups/billmtestrg/providers/Microsoft.OperationalInsights/workspaces/LAW-USAE2-ANALYTICS"
vmiTemplate="vmInsights.json"
vmiParams="vmInsightsParams.json"
ctiTemplate="changTrackInv.json"
ctiParams="changeTrackInvParams.json"

# Install the Azure Monitor Agent extension on the VM
echo "Installing Azure Monitor Agent on VM: $vmName"
az vm extension set \
  --resource-group $resourceGroup \
  --vm-name $vmName \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --enable-auto-upgrade true

# Install the Dependency Agent extension on the VM
echo "Installing Dependency Agent on VM: $vmName"
az vm extension set \
  --resource-group $resourceGroup \
  --vm-name $vmName \
  --name DependencyAgentLinux \
  --publisher Microsoft.Azure.Monitoring.DependencyAgent \
  --version 9.10.15

# Enable VM Insights
az deployment group create \
--resource-group $resourceGroup \
--template-file $vmiTemplate \
--parameters $vmiParams

# Install Change Tracking solution
az monitor log-analytics solution create \
  --resource-group $resourceGroup \
  --workspace $logAnalyticsWorkspaceProdId \
  --solution-type ChangeTracking

# Install Inventory solution
az monitor log-analytics solution create \
  --resource-group $resourceGroup \
  --workspace $logAnalyticsWorkspaceProdId \
  --solution-type Inventory

# Create ChangeTracking and Inventory DCR
az deployment group create \
--resource-group $resourceGroup \
--template-file $ctiTemplate \
--parameters $ctiParams

# Add Virtual Machine to the first Data Collection Rule
echo "Associating VM with Data Collection Rule: $dcrName"
az monitor data-collection rule association create \
 --name $dcrName \
 --rule-id $dcrId \
 --resource $vmResourceId

# Add Virtual Machine to the insights Data Collection Rule
echo "Associating VM with Data Collection Rule: $insightsDcrName"
az monitor data-collection rule association create \
 --name $insightsDcrName \
 --rule-id $insightsDcrId \
 --resource $vmResourceId

# Add Virtual Machine to the Change Tracking and Inventory Collection Rule
echo "Associating VM with Data Collection Rule: $chTrackingInvName"
az monitor data-collection rule association create \
 --name $chTrackingInvName \
 --rule-id $chTrackingInvId \
 --resource $vmResourceId

# Verify the extension installation
echo "Verifying extension installation..."
az vm extension show --resource-group $resourceGroup --vm-name $vmName --name AzureMonitorLinuxAgent

# Check if the DCRs are associated
echo "Checking DCR associations..."
dcrAssociation=$(az monitor data-collection rule association list --resource-group $resourceGroup --resource $vmResourceId)
echo "DCR Associations: $dcrAssociation"

if [[ $dcrAssociation == *"$dcrId"* && $dcrAssociation == *"$insightsDcrId"* ]]; then
  echo "Both DCRs successfully associated with VM."
else
  echo "One or both DCRs not associated with VM. Please check the settings and try again."
fi