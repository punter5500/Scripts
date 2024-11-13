# Connect to Azure Commercial
#Connect-AzAccount -Environment AzureCloud -Subscription "175910c1-ee75-46ff-a7b0-855b0504835d"

# Connect to Azure Gov
#Connect-AzAccount -Environment AzureUSGovernment -Subscription 

# Get information about the VM
$vm = Get-AzVM -ResourceGroupName "RG-USAE2-SECURITY-BEYONDTRUST-REMOTESUPPORT" -Name "usae2psecbtrs02"

# Define the tags to create
$tags = @{
    "Application"="BeyondTrust";
    "BackupPolicy"="VirtualMachine-Tier4";
    "CustomerRef"="MOO";
    "Environment"="Production";
    "Instance"="2";
    "Name"="secbtrs";
    "Namespace"="Security";
    "OperatingGroup"="Corporate";
    "Provisioner"="PowerShell";
    "RegionCode"="USAE2";
    "Role"="Beyond Trust Remote Support";
    "ServiceNowAssignmentGroup"="Security Operations";
    "UpdateGroup"="Appliance"
}

# Apply the Tags
Update-AzTag -ResourceId $vm.Id -Tag $tags -Operation Merge