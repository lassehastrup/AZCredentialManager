#Requires -Modules  Az.Accounts,Az.Resources
function Connect-AZCredentialManager {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $KeyVaultName,

        [Parameter()]
        [string]
        $UserName
    )
    try {
        if (!(Get-AzContext)) {
            Connect-AzAccount -CertificateThumbprint $ThumbPrint -ApplicationId $ApplicationID-Tenant $TenantId -ServicePrincipal
        }
        $Secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $Credential -AsPlainText
        New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$UserName", $Secret
    }
    catch {
        $_
    }
}