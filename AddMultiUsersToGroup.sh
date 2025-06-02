# Script to add multiple users to an Azure AD group

# --- Configuration ---
# Replace with the display name or object ID of your target group
GROUP_NAME_OR_ID="CommAAD-CloudApplication-Sharepoint-LegalCompliance-Access" 

# List of user principal names (UPNs) or object IDs of the users to add
# Example: USER_IDENTIFIERS=("user1@yourdomain.com" "user2@yourdomain.com" "anotheruser_object_id")
USER_IDENTIFIERS=(
    "ekelly3@moog.com"
    "ddriver@moog.com"
    "mclarke2@moog.com"
    "jclarke2@moog.com"
    "bbenabdallah@moog.com"
    "sroche@moog.com"
    "mcannata@moog.com"
    "pkrey@moog.com"
    "jhaley2@moog.com"
    "gkybett@moog.com"
    "wlashley@moog.com"
    "alynch@moog.com"
    "fmulla@moog.com"
    "jpolniak@moog.com"
    "tpopek@moog.com"
    "Jennifer jschamberger@moog.com"
    "chavas@moog.com"
    "jwilliams2@moog.com"
    "kpaquette@moog.com"
    "kstruck@moog.com"
    "trall2@moog.com"
    "lwierzbicki@moog.com"
    "hlucek@moog.com"
    "kbirkman@moog.com"
    "nmanjunath2@moog.com"
    "jtucker@moog.com"
)
# --- End Configuration ---

echo "Attempting to add users to group: $GROUP_NAME_OR_ID"

# Get the Object ID of the group
GROUP_OBJECT_ID=$(az ad group show --group "$GROUP_NAME_OR_ID" --query id --output tsv 2>/dev/null)

if [ -z "$GROUP_OBJECT_ID" ]; then
    echo "Error: Group '$GROUP_NAME_OR_ID' not found. Please check the group name or ID."
    exit 1
fi

echo "Group '$GROUP_NAME_OR_ID' found with Object ID: $GROUP_OBJECT_ID"

# Loop through each user and add them to the group
for USER_IDENTIFIER in "${USER_IDENTIFIERS[@]}"; do
    echo "Processing user: $USER_IDENTIFIER"

    # Get the Object ID of the user
    # We try to get the user by UPN first, then by object ID if the UPN fails (assuming it's an object ID)
    USER_OBJECT_ID=$(az ad user show --id "$USER_IDENTIFIER" --query id --output tsv 2>/dev/null)

    if [ -z "$USER_OBJECT_ID" ]; then
        echo "Warning: User '$USER_IDENTIFIER' not found. Skipping."
        continue # Skip to the next user
    fi

    echo "User '$USER_IDENTIFIER' found with Object ID: $USER_OBJECT_ID"

    # Add the user to the group
    az ad group member add \
        --group "$GROUP_OBJECT_ID" \
        --member-id "$USER_OBJECT_ID" \
        --query "{DisplayName:displayName, Id:id}" \
        --output tsv 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "Successfully added user '$USER_IDENTIFIER' to group."
    else
        # Check if the user is already a member (a common reason for non-zero exit code)
        if az ad group member check --group "$GROUP_OBJECT_ID" --member-id "$USER_OBJECT_ID" --query "value" --output tsv 2>/dev/null | grep -q "true"; then
            echo "User '$USER_IDENTIFIER' is already a member of the group. Skipping."
        else
            echo "Error: Failed to add user '$USER_IDENTIFIER' to group. Check permissions or a more detailed error may be above."
        fi
    fi
    echo "" # Add a newline for better readability between users
done

echo "Script execution complete."