Connect-AzureAD
Connect-MsolService

$Users = Get-msoluser -All | Where-Object { $_.UserType -ne "Guest" }
$Report = [System.Collections.Generic.List[Object]]::new() # Create output file 

ForEach ($User in $Users) {
    $MFADefaultMethod = ($User.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq $true }).MethodType
    $MFAPhoneNumber = $User.StrongAuthenticationDetails.PhoneNumber
    $PrimarySMTP = $User.Identifiers | Where-Object { $_.Issuer -eq "smtp" } | ForEach-Object { $_.Value }
    $Aliases = $User.Identifiers | Where-Object { $_.Issuer -eq "smtp" } | ForEach-Object { $_.Value }

    if ($User.StrongAuthenticationRequirements) {
        $MFAState = $User.StrongAuthenticationRequirements.State
    } else {
        $MFAState = 'Disabled'
    }

    if ($MFADefaultMethod) {
        Switch ($MFADefaultMethod) {
            "OneWaySMS" { $MFADefaultMethod = "Text code authentication phone" }
            "TwoWayVoiceMobile" { $MFADefaultMethod = "Call authentication phone" }
            "TwoWayVoiceOffice" { $MFADefaultMethod = "Call office phone" }
            "PhoneAppOTP" { $MFADefaultMethod = "Authenticator app or hardware token" }
            "PhoneAppNotification" { $MFADefaultMethod = "Microsoft Authenticator app" }
        }
    } else {
        $MFADefaultMethod = "Not enabled"
    }

    $ReportLine = [PSCustomObject] @{
        UserPrincipalName = $User.UserPrincipalName
        DisplayName       = $User.DisplayName
        MFAState          = $MFAState
        MFADefaultMethod  = $MFADefaultMethod
        MFAPhoneNumber    = $MFAPhoneNumber
        PrimarySMTP       = ($PrimarySMTP -join ',')
        Aliases           = ($Aliases -join ',')
        ObjectId          = $User.ObjectId
    }

    $Report.Add($ReportLine)
}

$Report | Where-Object { $_.MFADefaultMethod -notlike "Not enabled" } | Select-Object UserPrincipalName, DisplayName, MFADefaultMethod, PrimarySMTP

foreach ($user in $Users) {
    $userId = $user.ObjectId
    Revoke-AzureADUserAllRefreshToken -ObjectId $userId
}
