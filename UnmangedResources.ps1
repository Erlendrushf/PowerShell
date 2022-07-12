#Script to check for unused/unmanaged resources for cost savings


$unattachedDisks = Get-AzDisk | where-object DiskState -eq 'unattached' | select-object Resourcegroupname,name,DiskSizeGB,Tier,Location

$unattachedPips = @()
$unattachedPips = Get-AzPublicIpAddress | where-object IpConfiguration -eq $null | select-object Name,ResourceGroupName

$ChildlessLb = @()
$Lbs = @()
$Lbs = Get-AzLoadBalancer | select-object ResourceGroupName,Name

foreach($lb in $lbs) {
    if (($lb | get-azloadbalancerbackendaddresspool).BackendIpConfigurations.Count -lt 1) {
        $ChildlessLb += $lb
    }
}

$highrepSa = @()
$sas = @()
$sas = Get-AzStorageAccount | select-Object ResourceGroupName,StorageAccountName

foreach($sa in $sas) {
    if ((Get-AzStorageAccount -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName).Sku.name -notlike 'Standard_LRS'-and (Get-AzStorageAccount -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName).Sku.name -notlike 'Premium_LRS') {
        $highrepSa += $sa
    }
}


#outputs from script

if ($unattachedDisks.count -gt 0) {
    Write-Output "You have some unattached disks, and they are: " $unattachedDisks
}

if ($unattachedPips -notlike $null) {
    Write-Output "You have some unused Public IP Addresses, and they are: " $unattachedPips
}

Write-Output "You have " $ChildlessLb.count " Load Balancers without a backend pool"
if ($ChildlessLb.count -gt 0) {
    Write-Output "And they are: " $ChildlessLb
}

Write-Output "You have " $highrepSa.count " Storage accounts with high replication configured"
if ($highrepSa.count -gt 0) {
    Write-Output "And they are: " $highrepSa
}

