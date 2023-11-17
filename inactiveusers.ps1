$clientId = $env:CLIENT
$clientSecret = $env:SECRET
$tenantId = $env:TENANT

# Import the Microsoft Graph module
Import-Module Microsoft.Graph -Force

# Connect to Microsoft Graph
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -ClientSecret (ConvertTo-SecureString $clientSecret -AsPlainText -Force)

$groupObjectId = $env:GROUP_OBJECT_ID
$daysThreshold = 30
$currentDate = Get-Date
$addedUsers = @()

# Fetch users; adjust the query as per your requirement
$users = Get-MgUser -Filter "accountEnabled eq true"

Write-Output "Start the process of users..."

foreach ($user in $users) {
    # Logic to determine user's last sign-in. This will need to be updated based on available Microsoft Graph queries.
    # Placeholder for your logic to get the last sign-in date

    # Check if user meets criteria and then add to group
    if ($meetsCriteria) {
        # Placeholder for your logic to add user to group using Microsoft Graph
        $addedUsers += $user.DisplayName
        Write-Output "Added user $($user.DisplayName) to group."
    } else {
        Write-Output "User skipped $($user.DisplayName)."
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph

# Teams Webhook URL
$teamsWebhookUrl = $env:TEAM_WEBHOOK_URL

if ($addedUsers.Count -gt 0) {
    Write-Output "Sending message to Teams webhook"
    $message = "The following users were added to the group due to inactivity: `n" + ($addedUsers -join "`n")

    try {
        $body = @{
            text = $message
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -Body $body -ContentType 'application/json'

        Write-Output "Message sent to Teams successfully."
    } catch {
        Write-Output "Error sending message to Teams: $_"
    }
}
