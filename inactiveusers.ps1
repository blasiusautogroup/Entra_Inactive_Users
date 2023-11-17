Import-Module AzureAD

$clientId = $env:CLIENT
$clientSecret = $env:SECRET
$tenantId = $env:TENANT

$securePassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$psCredential = New-Object System.Management.Automation.PSCredential ($clientId, $securePassword)

Connect-AzureAD -TenantId $tenantId -ApplicationId $clientId -AadAccessToken $psCredential.Secret

$groupObjectId = $env:GROUP_OBJECT_ID
$daysThreshold = 30
$currentDate = Get-Date
$addedUsers = @()

$users = Get-AzureADUser -All $true

foreach ($user in $users) {
    $lastSignIn = (Get-AzureADUserSignInLogs -ObjectId $user.ObjectId | Sort-Object CreatedDateTime -Descending | Select-Object -First 1).CreatedDateTime

    if ($lastSignIn -and ($currentDate - $lastSignIn).Days -gt $daysThreshold) {
        Add-AzureADGroupMember -ObjectId $groupObjectId -RefObjectId $user.ObjectId
        $addedUsers += $user.DisplayName
    }
}

Disconnect-AzureAD

# Teams Webhook URL
$teamsWebhookUrl = $env:TEAM_WEBHOOK_URL

if ($addedUsers.Count -gt 0) {
    $message = "The following users were added to the group due to inactivity: `n" + ($addedUsers -join "`n")
    
    $body = @{
        text = $message
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -Body $body -ContentType 'application/json'
}