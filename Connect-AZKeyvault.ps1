#Requires -Modules  Az.Accounts,Az.Resources
function Connect-AZCredentialManager {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $ThumbPrint,

        [Parameter()]
        [string]
        $TenantId,

        [Parameter()]
        [string]
        $ApplicationID

    )

    try {
        Connect-AzAccount -CertificateThumbprint $ThumbPrint -ApplicationId $ApplicationID-Tenant $TenantId -ServicePrincipal 
    }
    catch {
        $_
    }
}