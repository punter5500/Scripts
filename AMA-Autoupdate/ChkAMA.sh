# Output file
output_file="azure_monitor_agent_status.csv"

# Write CSV header
echo "Subscription,Resource Group,VM Name,Agent Status" > $output_file

# Get a list of all subscriptions
subscriptions=$(az account list --query "[].id" -o tsv)

# Loop through each subscription
for sub in $subscriptions; do
  echo "Checking subscription: $sub"
  
  # Set the current subscription
  az account set --subscription $sub
  
  # Get a list of all resource groups in the current subscription
  resource_groups=$(az group list --query "[].name" -o tsv)
  
  # Loop through each resource group
  for rg in $resource_groups; do
    echo "  Checking resource group: $rg"
    
    # Get a list of all VMs in the current resource group
    vms=$(az vm list --resource-group $rg --query "[].{Name:name}" -o tsv)
    
    if [ -z "$vms" ]; then
      echo "  No VMs exist in resource group: $rg"
      echo "$sub,$rg,,No VMs exist" >> $output_file
    else
      # Loop through each VM in the resource group
      for vmname in $vms; do
        # Check for Azure Monitor Windows Agent
        state=$(az vm extension show --resource-group $rg --vm-name $vmname --name AzureMonitorWindowsAgent --query "provisioningState" -o tsv 2>/dev/null)
        if [ "$state" == "Succeeded" ]; then
          echo "$sub,$rg,$vmname,Windows Agent Installed" >> $output_file
        else
          # Check for Azure Monitor Linux Agent
          state=$(az vm extension show --resource-group $rg --vm-name $vmname --name AzureMonitorLinuxAgent --query "provisioningState" -o tsv 2>/dev/null)
          if [ "$state" == "Succeeded" ]; then
            echo "$sub,$rg,$vmname,Linux Agent Installed" >> $output_file
          else
            echo "$sub,$rg,$vmname,No Azure Monitor Agent Installed" >> $output_file
          fi
        fi
      done
    fi
  done
done

echo "Results have been written to $output_file"