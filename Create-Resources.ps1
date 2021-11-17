#Requires -Modules  Az.Accounts,Az.Resources




#Create a new ResourceGroup
New-AzResourceGroup -Name 'rg-credentialmanager-test-001' -Location 'westeurope'

#Generate a SelfSigned Certificate locally
$Obj = @{
    Subject           = 'cer-crendentialmanager-test-001'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    NotAfter          = (Get-Date).AddYears(2)
}
$Cert = New-SelfSignedCertificate @obj


#Exporting the certificate
Export-Certificate -Cert "$($obj.CertStoreLocation)\$($cert.ThumbPrint)" -Type Cert -FilePath "$($(Get-Location).path)\$($obj.Subject.ToString()).cer"

$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$($(Get-Location).path)\$($obj.Subject.ToString()).cer")
$binCert = $cer.GetRawCertData()
$credValue = [System.Convert]::ToBase64String($binCert)


#Create a App Registraion and upload the certificate as base64
$AppRegistration = New-AzADApplication -DisplayName 'appreg-credentialmanager-test-001' -CertValue $credValue


#Create Keyvault and assign permissions
$Kvault = New-AzKeyVault -ResourceGroupName 'rg-credentialmanager-test-001' -Name 'kv-credentialmanagerdemo' -Location 'westeurope' -sku 'standard'
Set-AzKeyVaultAccessPolicy -VaultName 'kv-credentialmanagerdemo' -ServicePrincipalName $Appregistration.ApplicationId.guid -PermissionsToSecrets get


#create a credential object to retrieve
$secretvalue = ConvertTo-SecureString "securePassword1" -AsPlainText -Force
$secret = Set-AzKeyVaultSecret -VaultName "kv-credentialmanagerdemo" -Name "User1" -SecretValue $secretvalue


Disconnect-AzAccount

Connect-AzAccount -CertificateThumbprint $cer.Thumbprint -ApplicationId 8afebfa1-c674-4c10-9af3-2d885aeccbff -ServicePrincipal -Tenant 057ea9a3-ad57-4c97-bf75-ad494ec38d64


Get-AzKeyVaultSecret -VaultName "kv-credentialmanagerdemo" -Name "User1" -AsPlainText


