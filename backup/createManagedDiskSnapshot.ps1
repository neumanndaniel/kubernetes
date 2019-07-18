#Parameter section
Param
(
    [Parameter(Mandatory = $true, HelpMessage = 'Resource id of the managed disk')]
    [String]
    $managedDiskResourceId,
    [Parameter(Mandatory = $true, HelpMessage = 'Retention time in days for the managed disk snapshots')]
    [String]
    $retentionTime,
    [Parameter(Mandatory = $true, HelpMessage = 'Resource group name for the managed disk snapshots')]
    [String]
    $resourceGroupName,
    [Parameter(Mandatory = $true, HelpMessage = 'Resource id of the storage account name of the Azure table storage')]
    [String]
    $storageAccountResourceId,
    [Parameter(Mandatory = $true, HelpMessage = 'Name of the Azure table storage')]
    [String]
    $storageTableName
)

#Login section
"Logging in..."
$connectionName = "AzureRunAsConnection"
try {
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    $null = Add-AzureRmAccount `
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

"Getting / setting inputs..."
$parameterInput = ($managedDiskResourceId -split "/")
$diskName = $parameterInput[8]
$resourceGroup = $parameterInput[4]
$managedDisk = Get-AzureRmDisk -ResourceGroupName $resourceGroup -DiskName $diskName
$date = Get-Date

$storageParameterInput = ($storageAccountResourceId -split "/")
$storageAccountName = $storageParameterInput[8]
$resourceGroupStorage = $storageParameterInput[4]

$resourceGroupCheck = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $managedDisk.Location
if (!$resourceGroupCheck) {
    "Initial resource group setup..."
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $managedDisk.Location
}

"Creating snapshot..."
$snapshotConfig = New-AzureRmSnapshotConfig `
    -SourceResourceId $managedDiskResourceId -Location $managedDisk.location -SkuName Standard_LRS `
    -CreateOption copy -Tag @{createdOn = "$date"; retentionTime = "$retentionTime"}

$snapshotName = $diskName + "-" + $date.Year + "-" + $date.Month + "-" + $date.Day + "-" + $date.Hour + "-" + $date.Minute
$snapshot = New-AzureRmSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig


"Getting storage context..."
$storageContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupStorage -Name $storageAccountName).Context
$table = Get-AzureStorageTable -Name $storageTableName -Context $storageContext

"Writing table..."
$dateParitionKey = [String]$date.Year + "-" + [String]$date.Month + "-" + [String]$date.Day
$array = @{"azureRegion" = $managedDisk.Location; "retentionTime" = $retentionTime; "resourceId" = $snapshot.Id}
Add-StorageTableRow -table $table -partitionKey $dateParitionKey -rowKey $snapshotName -property $array -ErrorAction Continue

"Removing old backups..."
[System.Collections.ArrayList]$backupTableStorage = (Get-AzureStorageTableRowAll $table)
$daysBack = "-" + $retentionTime
$oldDate = (Get-Date).AddDays($daysBack)
$oldDateParitionKey = [String]$oldDate.Year + "-" + [String]$oldDate.Month + "-" + [String]$oldDate.Day
foreach ($item in $backupTableStorage) {
    if ($item.PartitionKey -eq $oldDateParitionKey) {
        Remove-AzureStorageTableRow -table $table -partitionKey $item.PartitionKey -rowKey $item.RowKey -Verbose
        Remove-AzureRmResource -ResourceId $item.resourceId -Force
    }
}
