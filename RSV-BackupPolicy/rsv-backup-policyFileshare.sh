#!/bin/bash

# Login
#az cloud set --name AzureUSGovernment
az cloud set --name AzureCloud
az login --use-device-code

# Get the list of all subscriptions
subscriptions=$(az account list --output json)

# Create the CSV file and add the header
echo "SubscriptionName,PolicyName,RetentionDays,RetentionWeeks,RetentionMonths,RetentionYears,RunFreq,WorkloadType,IdSegment,RecoveryServicesVault,SnapshotRetentionDays,SnapshotType" > policy.csv
# ,StorageReplicationType,CrossRegionRestore

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
                # Get the storage replication type
                #storageReplicationType=$(az backup vault show --resource-group "$resourceGroup" --name "$vault" --query "properties.storageType" --output tsv)

                # Get the status of Cross Region Restore
                #crossRegionRestore=$(az backup vault show --resource-group "$resourceGroup" --name "$vault" --query "properties.crossRegionRestore" --output tsv)

                # Get the list of all policies in the vault
                policies=$(az backup policy list --resource-group "$resourceGroup" --vault-name "$vault" --output json)
                for policy in $(echo "${policies}" | jq -r '.[] | @base64'); do
                    _jq_policy() {
                        echo ${policy} | base64 --decode | jq -r ${1}
                    }
                    policyName=$(_jq_policy '.name')

                    # Filter policies that contain "VirtualMachine"
                    if [[ $policyName == File* ]]; then
                        # Get the backup policy details
                        policyDetails=$(az backup policy show --resource-group "$resourceGroup" --vault-name "$vault" --name "$policyName" --query "{PolicyName: name, RetentionDays: properties.retentionPolicy.dailySchedule.retentionDuration.count, RetentionWeeks: properties.retentionPolicy.weeklySchedule.retentionDuration.count, RetentionMonths: properties.retentionPolicy.monthlySchedule.retentionDuration.count, RetentionYears: properties.retentionPolicy.yearlySchedule.retentionDuration.count, RunFreq: properties.schedulePolicy.scheduleRunFrequency, Id: id, WorkloadType: properties.workLoadType, SnapshotRetentionDays: properties.instantRpRetentionRangeInDays, SnapshotType: properties.snapshotType}" --output json 2>/dev/null)
                        echo "Policy Details for $policyName: $policyDetails"  # Debugging output
                        if [ -n "$policyDetails" ]; then
                            # Parse the policy JSON and create a CSV entry
                            policyJson=$(echo "$policyDetails" | jq -r '.')
                            policyName=$(echo "$policyJson" | jq -r '.PolicyName')
                            retentionDays=$(echo "$policyJson" | jq -r '.RetentionDays')
                            retentionWeeks=$(echo "$policyJson" | jq -r '.RetentionWeeks')
                            retentionMonths=$(echo "$policyJson" | jq -r '.RetentionMonths')
                            retentionYears=$(echo "$policyJson" | jq -r '.RetentionYears')
                            runFreq=$(echo "$policyJson" | jq -r '.RunFreq')
                            idSegment=$(echo "$policyJson" | jq -r '.Id' | awk -F'/' '{print $8}')
                            workloadType=$(echo "$policyJson" | jq -r '.WorkloadType')
                            snapshotRetentionDays=$(echo "$policyJson" | jq -r '.SnapshotRetentionDays')
                            #snapshotType=$(echo "$policyJson" | jq -r '.SnapshotType')

                            # Append the data to the CSV file
                            echo "$subscriptionName,$policyName,$retentionDays,$retentionWeeks,$retentionMonths,$retentionYears,$runFreq,$idSegment,$workloadType,$vault,$snapshotRetentionDays,$snapshotType" >> policy.csv
                            #,$storageReplicationType,$crossRegionRestore

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
