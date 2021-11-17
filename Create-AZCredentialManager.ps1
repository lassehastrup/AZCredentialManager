#Requires -Modules  Az.Accounts,Az.Resources
function Create-AZCredentialManager {
    
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $TenantId,

        [ValidatePattern('^[-\w\._\(\)]+$')] 
        [string] 
        $ResourcegroupName,
    
        [Parameter()]
        [ValidateSet ('centralus', 'eastasia', 'southeastasia', 'eastus', 'eastus2', 'westus', 'westus2', 'northcentralus', 'southcentralus', 'westcentralus', 'northeurope', 'westeurope', 'japaneast', 'japanwest', 'brazilsouth', 'australiasoutheast', 'australiaeast', 'westindia', 'southindia', 'centralindia', 'canadacentral', 'canadaeast', 'uksouth', 'ukwest', 'koreacentral', 'francecentral', 'southafricanorth', 'uaenorth', 'australiacentral', 'switzerlandnorth', 'germanywestcentral', 'norwayeast', 'jioindiawest', 'westus3', 'swedencentral', 'australiacentral2')]
        $location,

        [ValidatePattern('^[a-zA-Z0-9-]{3,24}$')] 
        [string]
        $KeyVaultName,

        [ValidateSet('Cert:\CurrentUser\My', 'Cert:\LocalMachine\My')]
        [string]
        $CertificateStorePath,

        [Parameter()]
        [string]
        $CertificateSubject,

        [Parameter()]
        [string]
        $ServicePrincipalName,

        [Parameter()]
        [int]
        $CertificateExpirationDateInYears
    )
    try {
        $modules = @('Az.Accounts', 'Az.Resources') | ForEach-Object { Import-Module $_ }
        Connect-AzAccount
    }
    catch {
        $_
        Break
        
    }
    try {
        #suppress new cmdlet warnings
        Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
        #Create new ResourceGroup
        $ResourceGroup = New-AzResourceGroup -Name $ResourcegroupName -Location $location
        
        #Create SelfSigned Certficate
        $Obj = @{
            Subject           = $CertificateSubject
            CertStoreLocation = $CertificateStorePath
            NotAfter          = (Get-Date).AddYears($CertificateExpirationDateInYears)
        }
        $Cert = New-SelfSignedCertificate @obj
        
        #Exporting Certificate
        Export-Certificate -Cert "$($obj.CertStoreLocation)\$($cert.ThumbPrint)" -Type Cert -FilePath "$($(Get-Location).path)\$($obj.Subject.ToString()).cer"
        
        #Converting Certificate to Base64
        $cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$($(Get-Location).path)\$($obj.Subject.ToString()).cer")
        $binCert = $cer.GetRawCertData()
        $credValue = [System.Convert]::ToBase64String($binCert)

        #Creating an App Registration and uploading the certificate
        $ServicePrincipal = New-AzADServicePrincipal -DisplayName $ServicePrincipalName -CertValue $credValue
        do { 
            $ServicePrincipal = Get-AzADServicePrincipal -DisplayName $ServicePrincipalName
        }until ($ServicePrincipal)

        do {
            $ResourceGroup = Get-AzResourceGroup -Name $ResourcegroupName
        }
        until ($ResourceGroup)
        $Kvault = New-AzKeyVault -ResourceGroupName $ResourcegroupName -Name $KeyVaultName -Location $location -sku 'standard'
        Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $ServicePrincipal.Id -PermissionsToSecrets get
        
        [PSCustomObject]@{
            ThumbPrint    = $cer.Thumbprint
            TenantId      = $TenantId
            ApplicationID = (Get-AzADApplication -DisplayName $ServicePrincipalName).ApplicationId
        }
    }
    catch {
        $_
    }
}