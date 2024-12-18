#!/bin/bash


# Variables
# Gov
USER_EMAIL="pbuczkowski@moog.onmicrosoft.com"
RESOURCE_GROUPS_AND_SUBSCRIPTIONS=(
    "rg-usaga-adsap-solumina-activemq-dr,c74ec5fa-7686-4614-bbb8-611b7db3bb15"
"rg-usagv-adsap-3-solumina-activemq-dev,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-3-solumina-activemq-qa,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-4-solumina-activemq-qa,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-solumina-activemq,c74ec5fa-7686-4614-bbb8-611b7db3bb15"
"rg-usagv-adsap-solumina-activemq-dev,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-solumina-activemq-prep,c74ec5fa-7686-4614-bbb8-611b7db3bb15"
"rg-usagv-adsap-solumina-activemq-qa,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-solumina-activemq-sb,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-solumina-activemq-trn,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
"rg-usagv-adsap-solumina-bastion-np,25dbfa03-1f59-4081-9af1-f39a2d2095c9"
)

# Comm
##USER_EMAIL="pbuczkowski@mgclb.onmicrosoft.com"
##RESOURCE_GROUPS_AND_SUBSCRIPTIONS=(
##    "rg-gbaz1-adsap-3-solumina-activemq-qa,052f9f9a-9e2d-4451-ac9f-21cf7e67aacc"
##    "rg-gbaz1-adsap-solumina-activemq,33f84c50-5969-4576-a44b-611b287b3761"
##    "rg-gbaz1-adsap-solumina-activemq-prep,33f84c50-5969-4576-a44b-611b287b3761"
##    "rg-gbaz1-adsap-solumina-activemq-qa,052f9f9a-9e2d-4451-ac9f-21cf7e67aacc"
##    "rg-gbaz1-adsap-solumina-activemq-trn,052f9f9a-9e2d-4451-ac9f-21cf7e67aacc"
##    "rg-gbaz1-convergence-solumina-activemq-sb,4a3fec56-140a-476a-9993-5021c8c11239"
##    "RG-USAE2-AUTOMIC-ENGINE,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-autotime-application,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-autotime-keycloak,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-autotime-services,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-autotime-webclock,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-corp-logrhythm-data-index,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-prd-mdgdashboard,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usae2-security-beyondtrust-privilege-mgmt,175910c1-ee75-46ff-a7b0-855b0504835d"
##    "rg-usae2-sftp,ca791eb4-88bd-4177-b601-5b089086b3a5"
##    "rg-usaz2-autotime-application-dev,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-application-qa,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-application-sb,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-keycloak-dev,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-keycloak-qa,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-keycloak-sb,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-services-dev,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-services-qa,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-webclock-dev,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "rg-usaz2-autotime-webclock-qa,b01705ad-812a-437c-b0d0-d31b4d56272f"
##    "RG-USAZ2-AUTOMIC-ENGINE-TEST,b01705ad-812a-437c-b0d0-d31b4d56272f"
##)
ROLE="Virtual Machine Contributor"
CSV_FILE="role_assignments.csv"

# Create CSV file and add header
echo "User Email,Resource Group,Subscription ID,Role,Current Permissions" > $CSV_FILE

# Loop through each resource group and assign the role
for entry in "${RESOURCE_GROUPS_AND_SUBSCRIPTIONS[@]}"; do
    IFS=',' read -r RESOURCE_GROUP SUBSCRIPTION <<< "$entry"
    
    # Set the subscription
    az account set --subscription "$SUBSCRIPTION"
    
    # Assign the role with the scope parameter
    az role assignment create --assignee "$USER_EMAIL" --role "$ROLE" --scope "/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP"

    # Check current permissions
    CURRENT_PERMISSIONS=$(az role assignment list --assignee "$USER_EMAIL" --scope "/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP" --query "[].roleDefinitionName" -o tsv)
    
    # Append details to CSV file
    echo "$USER_EMAIL,$RESOURCE_GROUP,$SUBSCRIPTION,$ROLE,$CURRENT_PERMISSIONS" >> $CSV_FILE
    
    echo "User $USER_EMAIL has been added to the resource group $RESOURCE_GROUP in subscription $SUBSCRIPTION with $ROLE permissions."
done

echo "Role assignments and current permissions have been logged to $CSV_FILE."