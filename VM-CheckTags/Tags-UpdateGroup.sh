#!/bin/bash

# Ensure you are logged in to Azure
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Please log in to your Azure account using 'az login'."
    exit 1
fi

# Get a list of all subscriptions
subscriptions=$(az account list --query "[].{Name:name, SubscriptionId:id}" -o tsv)

# Create or clear the CSV file
output_file="vm_maintenance_configurations.csv"
echo "Subscription Name,VM Name,Resource Group,Update Group,Location,Maintenance Configuration ID" > "$output_file"

# Loop through each subscription and set it as the current subscription
while IFS=$'\t' read -r subscription_name subscription_id; do
    echo "Checking subscription: $subscription_name ($subscription_id)"
    az account set --subscription "$subscription_id"

    # Get a list of all virtual machines with their UpdateGroup and Location
    vms=$(az vm list --query "[].{Name:name, ResourceGroup:resourceGroup, UpdateGroup:tags.UpdateGroup, Location:location}" -o tsv)

    # Loop through each VM and run the az graph query
    while IFS=$'\t' read -r vm_name resource_group update_group location; do
        if [ -n "$update_group" ] && [ -n "$location" ]; then
            # Run the az graph query and capture the output
            query_output=$(az graph query -q "
            maintenanceresources 
            | where type == 'microsoft.maintenance/configurationassignments' 
            | where subscriptionId == '$subscription_id' 
            | where properties contains '$update_group' 
            | where properties contains '$location' 
            | project properties.maintenanceConfigurationId" -o json)

            # Extract the maintenanceConfigurationId from the query output
            maintenance_config_id=$(echo "$query_output" | jq -r '.data[0].properties_maintenanceConfigurationId' | awk -F'/' '{print $NF}')

            # Display the formatted output only once
            echo "Running query for VM: $vm_name, UpdateGroup: $update_group, Location: $location, $maintenance_config_id"

            # Append the result to the CSV file
            echo "$subscription_name,$vm_name,$resource_group,$update_group,$location,$maintenance_config_id" >> "$output_file"
        fi
    done <<< "$vms"
done <<< "$subscriptions"