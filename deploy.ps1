$ErrorActionPreference = "Stop"

$rg = 'rg_docker3'

$sp_name = "dockersp3"
$sp = ((az ad sp create-for-rbac --name $sp_name) | ConvertFrom-Json)
$assignment = (az role assignment create --assignee ("http://$($sp_name)") --role "Contributor" )

Write-Host 'Deploying resource group'
az deployment create `
    --name d_reg `
    --location westeurope `
    --template-file .\docker_rg.json `
    --parameters rgName=$rg

Write-Host 'Deploying network'
az group deployment create `
    --name d_network `
    -g $rg `
    --template-file .\docker_network.json

$vnet_name = 'vnet_docker'
$vnet_id = ((az network vnet show -g $rg -n $vnet_name) | ConvertFrom-Json).id

# Write-Host 'Deploying storage account'
$storageName = "scriptstoragedocker3"
az group deployment create `
    --name d_sa `
    -g $rg `
    --template-file .\docker_storage.json `
    --parameters sa_name=$storageName `
    --parameters vnet_id=$vnet_id

$storage_key = ((az storage account keys list --account-name $storageName) | ConvertFrom-Json)[0].value

az storage blob upload-batch `
    -d "scripts" -s ./scripts/ `
    --account-name $storageName `
    --account-key $storage_Key

$pip_ucp_name = 'vmucp-ip'
Write-Host 'Deploying ucp vm'
$appId = $sp.appId
$pwd = $sp.password
az group deployment create `
    --name d_ucp `
    -g $rg `
    --template-file .\docker_vm.json `
    --parameters .\docker_vm.ucp.parameters.json `
    --parameters storage_account_name=$storageName `
    --parameters storage_account_key=$storage_key `
    --parameters pip_name=$pip_ucp_name `
    --parameters aadClient_id=$appId `
    --parameters aad_client_secret=$pwd `
    --parameters resource_group=$rg --debug

$upc_ip = ((az network public-ip show -g $rg -n $pip_ucp_name) | ConvertFrom-Json).ipAddress
$upc_ip
$sp

# Write-Host 'Deploying dtr vm'
# az group deployment create `
#     --name d_ucp `
#     -g $rg `
#     --template-file .\docker_vm.json `
#     --parameters .\docker_vm.ucp.parameters.json `
#     --parameters storage_account_name=$storageName `
#     --parameters storage_account_key=$storage_key `
#     --parameters pip_name=$pip_ucp_name `
#     --parameters aadClient_id=$appId `
#     --parameters aad_client_secret=$pwd `
#     --parameters resource_group=$rg --debug

# az group deployment create `
#     --name d_dtr `
#     -g $rg `
#     --template-file .\docker_vm.json `
#     --parameters .\docker_vm.dtr.parameters.json `
#     --parameters script=(encodeScript ./scripts/dtr.sh)

# Write-Host 'Deploying wkr vm'
# az group deployment create `
#     --name d_wkr `
#     -g $rg `
#     --template-file .\docker_vm.json `
#     --parameters .\docker_vm.wkr.parameters.json `
#     --parameters script=(encodeScript ./scripts/wkr.sh)

# Write-Host 'Deploying test vm'
# az group deployment create `
#     --name d_test `
#     -g $rg `
#     --template-file .\docker_vm.json `
#     --parameters .\docker_vm.test.parameters.json

    