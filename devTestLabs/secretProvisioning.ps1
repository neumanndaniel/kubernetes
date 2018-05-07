Param
(
    [Parameter(Mandatory = $true, HelpMessage = 'Azure Key Vault name')]
    [String]
    $keyVaultName
)

#Variables section
$connectionName = "AzureRunAsConnection"
$aadServicePrincipalIdName = "kubernetesId"
$aadServicePrincipalSecretName = "kubernetesSecret"
$targetKeyVaultName = $keyVaultName.Split("/")
$targetKeyVaultName = $targetKeyVaultName[$targetKeyVaultName.Length - 1]
$resourceGroupName = $keyVaultName.Split("/")
$resourceGroupName = $resourceGroupName[$resourceGroupName.Length - 5]

#Azure login with Azure Automation service account
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Identifying source Key Vault of the Azure DevTest Lab
try {
    $keyVaults = (Get-AzureRmKeyVault -ResourceGroupName $resourceGroupName).VaultName
    $sourceKeyVaultName = $null
    foreach($item in $keyVaults) {
        $temp=$item -replace "[a-z]"
        if($temp.length -eq 4) {
            $sourceKeyVaultName = $item
        }
    }
}
catch {
    Write-Output 'ERROR:'
    Write-Output $_
}

#Set Azure Automation service principal access on target Key Vault
try {
    Set-AzureRmKeyVaultAccessPolicy -VaultName $targetKeyVaultName -ServicePrincipalName $servicePrincipalConnection.ApplicationId -PermissionsToSecrets all
}
catch {
    Write-Output 'ERROR:'
    Write-Output $_
}

#Read Kubernetes service principal id and secret from source Key Vault and write to target Key Vault
try {
    $aadServicePrincipalId = Get-AzureKeyVaultSecret -VaultName $sourceKeyVaultName -Name $aadServicePrincipalIdName
    $aadServicePrincipalSecret = Get-AzureKeyVaultSecret -VaultName $sourceKeyVaultName -Name $aadServicePrincipalSecretName
    $null=Set-AzureKeyVaultSecret -VaultName $targetKeyVaultName -Name $aadServicePrincipalIdName -SecretValue $aadServicePrincipalId.SecretValue
    $null=Set-AzureKeyVaultSecret -VaultName $targetKeyVaultName -Name $aadServicePrincipalSecretName -SecretValue $aadServicePrincipalSecret.SecretValue
}
catch {
    Write-Output 'ERROR:'
    Write-Output $_
}

#Revoke Azure Automation service principal access on target Key Vault
try {
    Set-AzureRmKeyVaultAccessPolicy -VaultName $targetKeyVaultName -ServicePrincipalName $servicePrincipalConnection.ApplicationId -PermissionsToSecrets @()
}
catch {
    Write-Output 'ERROR:'
    Write-Output $_
}
