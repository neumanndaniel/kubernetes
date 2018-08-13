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
$customRbacRoleName="dtlAksCredentials"
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

#Identifying target Key Vault of the Azure DevTest Lab
try {
    $temp=$targetKeyVaultName -replace "devtestlab",""
    if($temp.length -ne 4) {
        exit
    }
}
catch {
    Write-Output 'ERROR:'
    Write-Output $_
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
    $secretPermissions = 'backup', 'delete', 'get', 'list', 'recover', 'restore', 'set'
    Set-AzureRmKeyVaultAccessPolicy -VaultName $targetKeyVaultName -ServicePrincipalName $servicePrincipalConnection.ApplicationId -PermissionsToSecrets $secretPermissions
}
catch {
    Write-Output 'ERROR:'
    Write-Output $_
}

#Read Kubernetes service principal id, secret and custom RBAC role id from source Key Vault and write to target Key Vault
try {
    $aadServicePrincipalId = Get-AzureKeyVaultSecret -VaultName $sourceKeyVaultName -Name $aadServicePrincipalIdName
    $aadServicePrincipalSecret = Get-AzureKeyVaultSecret -VaultName $sourceKeyVaultName -Name $aadServicePrincipalSecretName
    $customRbacRole = Get-AzureKeyVaultSecret -VaultName $sourceKeyVaultName -Name $customRbacRoleName
    $null=Set-AzureKeyVaultSecret -VaultName $targetKeyVaultName -Name $aadServicePrincipalIdName -SecretValue $aadServicePrincipalId.SecretValue
    $null=Set-AzureKeyVaultSecret -VaultName $targetKeyVaultName -Name $aadServicePrincipalSecretName -SecretValue $aadServicePrincipalSecret.SecretValue
    $null=Set-AzureKeyVaultSecret -VaultName $targetKeyVaultName -Name $customRbacRoleName -SecretValue $customRbacRole.SecretValue
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
