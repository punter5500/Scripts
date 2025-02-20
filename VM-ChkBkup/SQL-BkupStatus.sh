#!/bin/bash

# Variables
resourceGroup="RG-USAZ2-AirCraftCommandCenter-Sandbox"
serverName="antdw-sqlserver-dev"
databaseName="antdw-dev"

# Get the backup retention policies
echo "Fetching backup retention policies for database: $databaseName"
az sql db ltr-policy show --resource-group "RG-USAZ2-AirCraftCommandCenter-Sandbox" --server "antdw-sqlserver-dev" --name "antdw-dev"