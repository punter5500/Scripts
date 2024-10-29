# Log in to your Azure account
#az login --use-device-code

# Get all subscriptions
subscriptions=$(az account list --query "[].{name:name, id:id}" -o tsv)

# Create or clear the CSV file
output_file="vms_without_virtualmachine_tier_tag.csv"
echo "VM Name,Resource Group,Subscription" > $output_file

# Loop through each subscription
while IFS=$'\t' read -r subscription_name subscription_id; do
    echo "Processing subscription: $subscription_name ($subscription_id)"
    
    # Set the current subscription
    az account set --subscription "$subscription_id"
    
    # Get all VMs in the current subscription
    vms=$(az vm list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)
    
    # Loop through each VM and check for the VirtualMachine-Tier tag
    while IFS=$'\t' read -r vm_name resource_group; do
        tags=$(az vm show --name "$vm_name" --resource-group "$resource_group" --query "tags" -o tsv)
        
        if [[ $tags != *"VirtualMachine-Tier"* ]]; then
            echo "$vm_name,$resource_group,$subscription_name" >> $output_file
        fi
    done <<< "$vms"
done <<< "$subscriptions"

# Generate HTML report
html_output_file="vms_without_virtualmachine_tier_tag.html"
{
    echo "<html>"
    echo "<head><title>VMs Without VirtualMachine-Tier Tag</title></head>"
    echo "<body>"
    echo "<h1>VMs Without VirtualMachine-Tier Tag</h1>"
    echo "<table border='1'>"
    echo "<tr><th>VM Name</th><th>Resource Group</th><th>Subscription</th></tr>"
    while IFS=',' read -r vm_name resource_group subscription_name; do
        echo "<tr><td>$vm_name</td><td>$resource_group</td><td>$subscription_name</td></tr>"
    done < <(tail -n +2 $output_file)
    echo "</table>"
    echo "</body>"
    echo "</html>"
} > $html_output_file

echo "Results have been saved to $output_file and $html_output_file"


### Log in to your Azure account
##az login --use-device-code
##
### Get all subscriptions
##subscriptions=$(az account list --query "[].{name:name, id:id}" -o tsv)
##
### Create or clear the CSV file
##output_file="vms_without_virtualmachine_tier_tag.csv"
##echo "VM Name,Resource Group,Subscription" > $output_file
##
### Loop through each subscription
##while IFS=$'\t' read -r subscription_name subscription_id; do
##    echo "Processing subscription: $subscription_name ($subscription_id)"
##    
##    # Set the current subscription
##    az account set --subscription "$subscription_id"
##    
##    # Get all VMs in the current subscription
##    vms=$(az vm list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)
##    
##    # Loop through each VM and check for the VirtualMachine-Tier tag
##    while IFS=$'\t' read -r vm_name resource_group; do
##        tags=$(az vm show --name "$vm_name" --resource-group "$resource_group" --query "tags" -o tsv)
##        
##        if [[ $tags != *"VirtualMachine-Tier"* ]]; then
##            echo "$vm_name,$resource_group,$subscription_name" >> $output_file
##        fi
##    done <<< "$vms"
##done <<< "$subscriptions"
##
##echo "Results have been saved to $output_file"