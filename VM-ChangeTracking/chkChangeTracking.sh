#!/bin/bash

# Login
#az cloud set --name AzureUSGovernment
az cloud set --name AzureCloud
az login --use-device-code

# Get the list of all subscriptions
subscriptions=$(az account list --output json)

# Output CSV file
output_file="change_tracking_report.csv"

# Create the CSV file and add the header
echo "Subscription,Resource Group,VM Name,Change Tracking Enabled" > $output_file

# Iterate over each subscription
for sub in $(echo "${subscriptions}" | jq -r '.[] | @base64'); do
    _jq_sub() {
        echo ${sub} | base64 --decode | jq -r ${1}
    }
    subscriptionId=$(_jq_sub '.id')
    subscriptionName=$(_jq_sub '.name')

    # Set the subscription context
    az account set --subscription "$subscriptionId"

    # Get all resource groups in the current subscription
    resource_groups=$(az group list --query "[].name" -o tsv)

    # Loop through each resource group
    for rg in $resource_groups; do
        # Skip resource groups that contain "citrix" or "databricks"
        if [[ "$rg" == *"citrix"* || "$rg" == *"databricks"* ]]; then
            echo "Skipping resource group: $rg"
            continue
        fi

        echo "Checking resource group: $rg"

        # Get all VMs in the current resource group
        vms=$(az vm list --resource-group "$rg" --query "[].name" -o tsv)

        # Loop through each VM
        for vm in $vms; do
            echo "Checking VM: $vm in Resource Group: $rg"

            # Check if Change Tracking extension is enabled
            EXTENSION=$(az vm extension list --resource-group "$rg" --vm-name "$vm" --query "[?contains(name, 'ChangeTracking')].{Name:name, Publisher:publisher, Type:type}" -o tsv)

            # Determine if Change Tracking is enabled
            if [ -z "$EXTENSION" ]; then
                change_tracking="No"
            else
                change_tracking="Yes"
            fi

            # Write result to CSV
            echo "$subscriptionName,$rg,$vm,$change_tracking" >> $output_file
        done
    done
done

echo "Report generated: $output_file"
