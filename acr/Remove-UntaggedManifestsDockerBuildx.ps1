$ACRS = Get-AzContainerRegistry
foreach ($ACR in $ACRS) {
  $ACR_CREDS = Get-AzContainerRegistryCredential -ResourceGroupName $ACR.ResourceGroupName -Name $ACR.Name
  [PSCredential]$CREDENTIAL = New-Object System.Management.Automation.PSCredential ($ACR_CREDS.Username, (ConvertTo-SecureString $ACR_CREDS.Password -AsPlainText -Force))
  $HEADERS = @{ 'accept' = 'application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json' }
  $ACR_URL = $ACR.LoginServer
  $REPOS = Get-AzContainerRegistryRepository -RegistryName $ACR.Name
  foreach ($REPO in $REPOS) {
    $EXCLUDE_LIST = @()
    Write-OutPut "########################"
    Write-Output "Processing repository: $REPO"
    $MANIFESTS = (Get-AzContainerRegistryManifest -RegistryName $ACR.Name -RepositoryName $REPO).ManifestsAttributes | Sort-Object -Property LastUpdateTime -Descending
    foreach ($ITEM in $MANIFESTS) {
      $TAG = $ITEM.digest
      $ITEM_DETAILS = Invoke-RestMethod -Uri https://$ACR_URL/v2/$REPO/manifests/$TAG -Authentication Basic -Method Get -Credential $CREDENTIAL -Headers $HEADERS
      if ($ITEM_DETAILS.manifests -ne $null) {
        $EXCLUDE_LIST += $ITEM_DETAILS.manifests.digest
      }
      if ($ITEM.Tags -eq $null -and $ITEM.digest -notin $EXCLUDE_LIST) {
        Write-OutPut "------------------------"
        Write-Output "Delete dangling image $REPO@$TAG"
        Remove-AzContainerRegistryManifest -RegistryName $ACR.Name -RepositoryName $REPO -Manifest $TAG
      }
    }
  }
}
