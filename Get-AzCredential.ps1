#Requires -Modules  Az.Accounts,Az.Resources
function Get-AzCredential {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $KeyVaultName,

        [Parameter()]
        [string]
        $CertificateThumbprint,

        [Parameter()]
        [string]
        $ApplicationId,
        
        [Parameter()]
        [string]
        $TenantId,

        [Parameter()]
        [string]
        $UserName
    )
    try {
        if (!(Get-AzContext)) {
            Connect-AzAccount -CertificateThumbprint $CertificateThumbprint -ApplicationId $ApplicationID -Tenant $TenantId -ServicePrincipal
        }
        $Secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $UserName -AsPlainText | ConvertTo-SecureString -AsPlainText -Force
        New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Secret
    }
    catch {
        $_
    }
}