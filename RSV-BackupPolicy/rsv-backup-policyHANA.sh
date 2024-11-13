#!/bin/bash

# Login
az cloud set --name AzureUSGovernment
#az cloud set --name AzureCloud
az login --use-device-code

# Get the list of all subscriptions
subscriptions=$(az account list --output json)

# Create the CSV file and add the header
echo "SubscriptionName,PolicyName,RetentionDays,RetentionWeeks,RetentionMonths,RetentionYears,IncrementalRetentionDays,SchedulePolicyType,ScheduleRunFrequency,ScheduleRunDays,WorkloadType,ResourceGroup,RecoveryServicesVault" > policy.csv

# Iterate over each subscription
for sub in $(echo "${subscriptions}" | jq -r '.[] | @base64'); do
    _jq_sub() {
     echo ${sub} | base64 --decode | jq -r ${1}
   }
   subscriptionId=$(_jq_sub '.id')
   subscriptionName=$(_jq_sub '.name')

   # Set the subscription context
   az account set --subscription "$subscriptionId"

   # Get the list of all backup vaults
   vaults=$(az backup vault list --output json)

   # Initialize arrays to store vault names and resource groups
   vaultLists=()
   resourceGroupLists=()

   # Parse the JSON response and populate the arrays
   for row in $(echo "${vaults}" | jq -r '.[] | @base64'); do
     _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
     }
     vaultLists+=($(_jq '.name'))
     resourceGroupLists+=($(_jq '.resourceGroup'))
   done

   # Iterate over each resource group and vault
   for resourceGroup in "${resourceGroupLists[@]}"; do
     for vault in "${vaultLists[@]}"; do
        # Check if the vault exists in the current resource group
        vaultExists=$(az backup vault show --resource-group "$resourceGroup" --name "$vault" --output json 2>/dev/null)
        if [ -n "$vaultExists" ]; then
          # Get the list of all policies in the vault
          policies=$(az backup policy list --resource-group "$resourceGroup" --vault-name "$vault" --output json)
          for policy in $(echo "${policies}" | jq -r '.[] | @base64'); do
             _jq_policy() {
               echo ${policy} | base64 --decode | jq -r ${1}
             }
             policyName=$(_jq_policy '.name')
             if [[ $policyName == HANADB-Tier* ]]; then
               # Get the backup policy details
               policyDetails=$(az backup policy show --resource-group "$resourceGroup" --vault-name "$vault" --name "$policyName" --query "{PolicyName: name, RetentionDays: properties.subProtectionPolicy[?policyType=='Full'].retentionPolicy.dailySchedule.retentionDuration.count | [0], RetentionWeeks: properties.subProtectionPolicy[?policyType=='Full'].retentionPolicy.weeklySchedule.retentionDuration.count  | [0], RetentionMonths: properties.subProtectionPolicy[?policyType=='Full'].retentionPolicy.monthlySchedule.retentionDuration.count | [0], IncrementalRetentionDays: properties.subProtectionPolicy[?policyType=='Incremental'].retentionPolicy.retentionDuration.count | [0], RetentionYears: properties.subProtectionPolicy[?policyType=='Full'].retentionPolicy.yearlySchedule.retentionDuration.count | [0], SchedulePolicyType: properties.subProtectionPolicy[?policyType=='Full'].schedulePolicy.schedulePolicyType, ScheduleRunFrequency: properties.subProtectionPolicy[?policyType=='Full'].schedulePolicy.scheduleRunFrequency, ScheduleRunDays: properties.subProtectionPolicy[?policyType=='Incremental'].schedulePolicy.scheduleRunDays, WorkloadType: properties.workLoadType, ResourceGroup: resourceGroup}" --output json 2>/dev/null)
               if [ -n "$policyDetails" ]; then
                   # Parse the policy JSON and create a CSV entry
                   policyJson=$(echo "$policyDetails" | jq -r '.')
                   policyName=$(echo "$policyJson" | jq -r '.PolicyName')
                   retentionDays=$(echo "$policyJson" | jq -r '.RetentionDays')
                   retentionWeeks=$(echo "$policyJson" | jq -r '.RetentionWeeks')
                   retentionMonths=$(echo "$policyJson" | jq -r '.RetentionMonths')
                   retentionYears=$(echo "$policyJson" | jq -r '.RetentionYears')
                   retentionIncDays=$(echo "$policyJson" | jq -r '.IncrementalRetentionDays')
                   schedulePolicyType=$(echo "$policyJson" | jq -r '.SchedulePolicyType | join(", ") // empty')
                   scheduleRunFrequency=$(echo "$policyJson" | jq -r '.ScheduleRunFrequency | join(", ") // empty')
                   scheduleRunDays=$(echo "$policyJson" | jq -r '.ScheduleRunDays[] | join(", ") // empty')
                   scheduleRunDays="[$scheduleRunDays]"
                   workloadType=$(echo "$policyJson" | jq -r '.WorkloadType')
                   resourceGroup=$(echo "$policyJson" | jq -r '.ResourceGroup')

                   # Debug output
                   echo "PolicyName: $policyName"
                   echo "RetentionDays: $retentionDays"
                   echo "RetentionWeeks: $retentionWeeks"
                   echo "RetentionMonths: $retentionMonths"
                   echo "RetentionYears: $retentionYears"
                   echo "IncrementalRetentionDays: $retentionIncDays"
                   echo "SchedulePolicyType: $schedulePolicyType"
                   echo "ScheduleRunFrequency: $scheduleRunFrequency"
                   echo "ScheduleRunDays: $scheduleRunDays"
                   echo "WorkloadType: $workloadType"
                   echo "ResourceGroup: $resourceGroup"

                   # Append the data to the CSV file
                   echo "$subscriptionName,$policyName,$retentionDays,$retentionWeeks,$retentionMonths,$retentionYears,$retentionIncDays,$schedulePolicyType,$scheduleRunFrequency,$scheduleRunDays,$workloadType,$resourceGroup,$vault" >> policy.csv

                   # Output the resource group and vault name
                   echo "Subscription: $subscriptionName"
                   echo "ResourceGroup: $resourceGroup"
                   echo "VaultList: $vault"
               else
                  echo "Error retrieving policy details for Policy: $policyName in Vault: $vault in ResourceGroup: $resourceGroup"
               fi
             fi
          done
        else
          echo "Vault: $vault not found in ResourceGroup: $resourceGroup"
        fi
     done
   done
done
