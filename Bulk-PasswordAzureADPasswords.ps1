Connect-AzureAD

# Get all Azure AD users
$users = Get-AzureADUser -All $true

# Specify the new password
$newPassword = sdsadadadasda  # Replace with the desired password

# Loop through each user and reset their password
foreach ($user in $users) {
    Set-AzureADUserPassword -ObjectId $user.ObjectId -Password $newPassword -ForceChangePasswordNextLogin $false
    Write-Host Password reset for $($user.UserPrincipalName)
}