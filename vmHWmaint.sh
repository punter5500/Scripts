#!/bin/bash

# Login to Azure if not already logged in
az account show > /dev/null 2>&1 || az login

# Get all subscriptions
subscriptions=$(az account list --query "[].id" -o tsv)

echo "Checking for VMs with hardware maintenance schedules..."

for sub in $subscriptions; do
  echo "Subscription: $sub"
  az account set --subscription "$sub"

  # Get all VMs in the subscription
  vms=$(az vm list --query "[].{name:name, resourceGroup:resourceGroup}" -o json)
your priority contacts.
Change settings


13:21

Chat


6
People


Raise


React


View


Notes


Apps


More


Camera



Mic



Stop sharing


Leave
  for row in $(echo "$vms" | jq -c '.[]'); do
    name=$(echo "$row" | jq -r '.name')
    rg=$(echo "$row" | jq -r '.resourceGroup')

    # Check for maintenance status
    maintenance=$(az vm get-instance-view --name "$name" --resource-group "$rg" \
      --query "maintenanceRedeployStatus" -o json)

    if [[ "$maintenance" != "null" && "$maintenance" != "{}" ]]; then
      echo "VM: $name in RG: $rg has a maintenance schedule:"
      echo "$maintenance" | jq
    fi
  done
done
