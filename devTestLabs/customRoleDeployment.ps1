$subscriptionId=az account show|ConvertFrom-Json
$roleDefinition='{
    "Name": "DTL AKS Credentials",
    "IsCustom": true,
    "Description": "Custom role for DTL users to get access to deployed AKS clusters",
    "Actions": [
        "Microsoft.ContainerService/managedClusters/accessProfiles/listCredential/action"
    ],
    "NotActions": [
    ],
    "AssignableScopes": [
        "/subscriptions/'+$subscriptionId.id+'"
    ]
}'
$roleDefinition|Out-File -FilePath ./customRole.json
az role definition create --role-definition ./customRole.json
