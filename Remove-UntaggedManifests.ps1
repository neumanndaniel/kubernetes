$ACRS = Get-AzContainerRegistry
foreach ($ACR in $ACRS) {
  $REPOS = Get-AzContainerRegistryRepository -RegistryName $ACR.Name
  foreach ($REPO in $REPOS) {
    $MANIFESTS = (Get-AzContainerRegistryManifest -RegistryName $ACR.Name -RepositoryName $REPO).ManifestsAttributes | Where-Object { $_.Tags -eq $null } | Sort-Object -Property LastUpdateTime -Descending
    foreach ($ITEM in $MANIFESTS) {
      $TAG = $ITEM.digest
      Write-OutPut "------------------------"
      Write-Output "Delete dangling image $REPO@$TAG"
      Remove-AzContainerRegistryManifest -RegistryName $ACR.Name -RepositoryName $REPO -Manifest $TAG
    }
  }
}
