Throw "This is not a robust file"

$oldVerbose = $VerbosePreference
$VerbosePreference = "continue" 

#Region Section 3 VM values declaration
Write-Verbose "Section 3 - VM values declaration"
$ResourceLocation = "NorthEurope"
$WVDLocation = "eastUS"
$vwdResourceGroupName = 'rg-wvd-neu'
$mgmtResourceGroupName = 'rg-mgmt-neu'
$vmName = Read-host -Prompt "Please Provide VM Name"
$date = Get-date -UFormat "%d_%m_%Y"
$snapshotName = "snap-" + $vmName + "_" + $date
$imageName = "img-" + $vmName + "_" + $date
#endregion

#Region Section 3 - Snapshoot Creation
Write-Verbose "Section 3 - Snapshoot Creation"
Write-Verbose "Looking for VM:'$vmName'"
$vm = Get-AzVM -ResourceGroupName $mgmtResourceGroupName -Name $vmName 
$diskID = $vm.StorageProfile.OsDisk.ManagedDisk.Id
Write-Verbose "Creating Snapshoot config for '$vmName' OSDisk '$diskID'"
$snapshot = New-AzSnapshotConfig -SourceUri $diskID -Location $resourceLocation -CreateOption copy
$snapshotTest = Get-AzSnapshot -SnapshotName $snapshotName -ResourceGroupName $mgmtResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $snapshotTest) {
    Write-Verbose "Creating new snapshot for VM: '$vmName', SnapshootName: '$snapshotName'"
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $mgmtResourceGroupName
}
else {
    Write-Verbose "Snapshot for VM: '$vmName', SnapshootName: '$snapshotName' already created."
}
#endregion

#region Section 3 - Create Image from VM
Write-Verbose "Section 3 - Create Image from VM"
Write-Verbose "Looking for VM:'$vmName'"
$vm = Get-AzVM -ResourceGroupName $mgmtResourceGroupName -Name $vmName 
$vmStatus = (Get-AZVM -ResourceGroupName $mgmtResourceGroupName -Name $vmName -status).statuses[1].DisplayStatus
if ($vmStatus -ne 'VM Deallocated') {
    Write-Verbose "Stopping vm:'$vmName'"
    Stop-AzVM -ResourceGroupName $mgmtResourceGroupName -Name $vmName -Force
}
else {
    Write-Verbose "VM:'$vmName' deallocated."
}
$diskID = $vm.StorageProfile.OsDisk.ManagedDisk.Id
$imageTest = Get-AZimage -ResourceGroupName $mgmtResourceGroupName -ImageName $imageName -ErrorAction SilentlyContinue
if ($null -eq $imageTest) {
    Write-Verbose "Creating image config for vm: '$vmName', OSDisk '$diskID'"
    $imageConfig = New-AzImageConfig -Location $resourceLocation
    $imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsState Generalized -OsType Windows -ManagedDiskId $diskID
    Write-Verbose "Creating new image for VM: '$vmName', imageName: '$imageName'"
    New-AzImage -ImageName $imageName -ResourceGroupName $mgmtResourceGroupName -Image $imageConfig
}
else {
    Write-Verbose "Image from VM: '$vmName', ImageName: ''$imageName' already created."
}
#endregion

#region Section 3 - Shared Image Gallery cration
Write-Verbose "Section 3 - Shared Image Gallery cration"
$galleryName = Read-host -Prompt "Please provide SharedImageGallery name"
$galleryTest = Get-AZGallery -ResourceGroupName $mgmtResourceGroupName -GalleryName $galleryName -ErrorAction SilentlyContinue
if ($null -eq $galleryTest) {
    Write-Verbose "Creating image gallery: '$galleryName'"
    New-AzGallery -GalleryName $galleryName -ResourceGroupName $mgmtResourceGroupName -Location $resourceLocation
}
else {
    Write-Verbose "Gallery '$galleryName' already created."
}
#endregion

#region Section 3 - Image upload to SIG
Write-Verbose "Section 3 - Image upload to SIG"
Write-Verbose "Looking for SharedImageGallery: '$galleryName'"
$gallery = Get-AzGallery -Name $galleryName -ResourceGroupName $mgmtResourceGroupName
$imageID = (Get-AzImage -ResourceGroupName $mgmtResourceGroupName -ImageName $imageName).id

Write-Verbose "Creating ImageDefinition"
$imageDefinition = New-AzGalleryImageDefinition -GalleryName $gallery.Name -ResourceGroupName $mgmtResourceGroupName -Location $resourceLocation -Name 'Windows10-MU-AcrobatDC' -OsState Generalized -OsType Windows -Publisher 'Azureblog' -Offer 'Azureblog' -Sku '1'

$region1 = @{Name='northeurope';ReplicaCount=1}
$targetRegions = @($region1)

Write-Verbose "Creating ImageVersion"
New-AzGalleryImageVersion -GalleryImageDefinitionName $imageDefinition.Name -GalleryImageVersionName '1.0.1' -GalleryName $gallery.Name -ResourceGroupName $mgmtResourceGroupName -Location $resourceLocation -TargetRegion $targetRegions -SourceImageId $imageID -PublishingProfileEndOfLifeDate '2021-10-06' -asJob 

#endregion
$VerbosePreference = $verboseSettings
