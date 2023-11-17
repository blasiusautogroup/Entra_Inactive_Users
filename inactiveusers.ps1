$clientId = $env:CLIENT
$clientSecret = $env:SECRET
$tenantId = $env:TENANT

# Convert secret to a secure string
$secureClientSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force

# Create a pscredent object with the client  and secret
$psCredential = New-Object System.Management.Automation.PSCredential ($clientId, $secureClientSecret)

# Get an access token
$token = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList $clientId, $secureClientSecret
$context = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$tenantId")
$accessToken = $context.AcquireTokenAsync("https://graph.microsoft.com", $token).Result.AccessToken

Connect-AzureAD -AadAccessToken $accessToken -AccountId $clientId -TenantId $tenantId


$groupObjectId = $env:GROUP_OBJECT_ID
$daysThreshold = 30
$currentDate = Get-Date
$addedUsers = @()

$users = Get-AzureADUser -All $true

Write-Output "start th process of users..."

foreach ($user in $users) {
    $lastSignIn = (Get-AzureADUserSignInLogs -ObjectId $user.ObjectId | Sort-Object CreatedDateTime -Descending | Select-Object -First 1).CreatedDateTime

    if ($lastSignIn -and ($currentDate - $lastSignIn).Days -gt $daysThreshold) {
        Add-AzureADGroupMember -ObjectId $groupObjectId -RefObjectId $user.ObjectId
        $addedUsers += $user.DisplayName
        Write-Output "Added user $($user.DisplayName) to group."
    }
    Write-Output "User skipped $($user.DisplayName) to group."
}

Disconnect-AzureAD

# Teams Webhook URL
$teamsWebhookUrl = $env:TEAM_WEBHOOK_URL

if ($addedUsers.Count -gt 0) {
    Write-Output "Sending message Teams webhook"
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