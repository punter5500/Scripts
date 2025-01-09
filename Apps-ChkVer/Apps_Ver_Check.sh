#!/bin/bash

# Log in to Azure
az logout

az cloud set --name AzureCloud
#az cloud set --name AzureUSGovernment
az login

# Get all subscriptions
subscriptions=$(az account list --query "[].id" -o tsv)

# Create a JSON file and initialize an empty array
output_file="azure_apps.json"
echo "[]" > $output_file

# Loop through each subscription
for subscription in $subscriptions; do
    echo "Checking subscription: $subscription"
    az account set --subscription $subscription
    
    # Get all web apps
    webapps=$(az webapp list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o tsv)
    # Get all function apps
    functionapps=$(az functionapp list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o tsv)
    # Get all Logic Apps
    logicapps=$(az logicapp list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o tsv)
    
    if [ -z "$webapps" ] && [ -z "$functionapps" ] && [ -z "$logicapps" ]; then
        echo "No apps found in subscription: $subscription"
    else
        echo "Apps in subscription: $subscription"
        
        echo "Web Apps:"
        while IFS=$'\t' read -r name resourceGroup; do
            echo "Name: $name, Resource Group: $resourceGroup"
            config=$(az resource show --resource-type "Microsoft.Web/sites" --name $name --resource-group $resourceGroup --query properties -o json)
            if [ -z "$config" ]; then
                config="{}"
            fi
            jq --arg subscription "$subscription" --arg appType "WebApp" --arg name "$name" --arg resourceGroup "$resourceGroup" --argjson config "$config" \
                '. += [{"Subscription": $subscription, "AppType": $appType, "Name": $name, "ResourceGroup": $resourceGroup, "Configuration": $config}]' \
                $output_file > tmp.$$.json && mv tmp.$$.json $output_file
        done <<< "$webapps"
        
        echo "Function Apps:"
        while IFS=$'\t' read -r name resourceGroup; do
            echo "Name: $name, Resource Group: $resourceGroup"
            config=$(az resource show --resource-type "Microsoft.Web/sites" --name $name --resource-group $resourceGroup --query properties -o json)
            if [ -z "$config" ]; then
                config="{}"
            fi
            jq --arg subscription "$subscription" --arg appType "FunctionApp" --arg name "$name" --arg resourceGroup "$resourceGroup" --argjson config "$config" \
                '. += [{"Subscription": $subscription, "AppType": $appType, "Name": $name, "ResourceGroup": $resourceGroup, "Configuration": $config}]' \
                $output_file > tmp.$$.json && mv tmp.$$.json $output_file
        done <<< "$functionapps"
        
        echo "Logic Apps:"
        while IFS=$'\t' read -r name resourceGroup; do
            echo "Name: $name, Resource Group: $resourceGroup"
            config=$(az resource show --resource-type "Microsoft.Logic/workflows" --name $name --resource-group $resourceGroup --query properties -o json)
            if [ -z "$config" ]; then
                config="{}"
            fi
            jq --arg subscription "$subscription" --arg appType "LogicApp" --arg name "$name" --arg resourceGroup "$resourceGroup" --argjson config "$config" \
                '. += [{"Subscription": $subscription, "AppType": $appType, "Name": $name, "ResourceGroup": $resourceGroup, "Configuration": $config}]' \
                $output_file > tmp.$$.json && mv tmp.$$.json $output_file
        done <<< "$logicapps"
    fi
done

echo "Results have been written to $output_file"
