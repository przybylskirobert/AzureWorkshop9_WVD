Throw "This is not a robust file"

$oldVerbose = $VerbosePreference
$VerbosePreference = "continue" 

#Region Section 1 Confguring Variables
Write-Verbose "Section 1 - Configuring variables"
Install-module Az.DesktopVirtualization

import-module Az.DesktopVirtualization
$ResourceLocation = "NorthEurope"
$WVDLocation = "eastUS"
$vwdResourceGroupName = 'rg-wvd-neu'
$mgmtResourceGroupName = 'rg-mgmt-neu'
$prefix = 'AZWorkshop'
$maxLimit = 2
$WVDusersGroupName = 'WVD_Users'

$WVDConfig = @(
    $(New-Object PSObject -Property @{WorkspaceName = "$($prefix)_WSPACE_DESKTOP"; HostPoolName = "$($prefix)_HOST_POOL_DESKTOP"; AppGroupeName = "$($prefix)_APP_GROUP_DESKTOP"; PreferedAppGroupType = 'Desktop'; FriendlyName = "$($prefix)_DSK" })
)

Connect-AzureAD
$wvd_UsersGroup = Get-AzureADGroup -SearchString $WVDusersGroupName
#endregion

#Region Section 1 Resource group Creation
Write-Verbose "Section 1 - Configuring resource groups"
Connect-AzAccount
New-AzResourceGroup -Name $vwdResourceGroupName -Location $ResourceLocation -Force
New-AzResourceGroup -Name $mgmtResourceGroupName -Location $ResourceLocation -Force
#endregion

#Region Section 1 WVD core resources deployment
Write-Verbose "Section 1 - WVD core resources deployment"
foreach ($entry in $WVDConfig) {
    $workspaceName = $entry.WorkspaceName
    $hostPoolName = $entry.HostPoolName
    $appGroupName = $entry.AppGroupeName
    $preferedAppGroupType = $entry.PreferedAppGroupType
    $friendlyName = $entry.FriendlyName

    if ($preferedAppGroupType -eq "Desktop") {
        $aplicationGroupType = "Desktop"
    }
    else {
        $aplicationGroupType = "RemoteApp"
    }

    $workspacetest = Get-AzWvdWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($workspacetest.count -eq 0) {
        Write-Verbose "Creating new Workspace:'$workspaceName' in resourcegroup: '$ResourceGroupName', under location: '$WVDLocation'"
        New-AzWvdWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -Location $WVDLocation
    }
    else {
        Write-Verbose "Workspace:'$workspaceName' already exist."
    }
    $hostpooltest = Get-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $ResourceGroupName  -ErrorAction SilentlyContinue
    if ($hostpooltest.count -eq 0) {
        Write-Verbose "Creating new HostPool :'$hostPoolName' in resourcegroup: '$ResourceGroupName', under location: '$WVDLocation'"
        New-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $ResourceGroupName -Location $WVDLocation -HostPoolType Pooled -LoadBalancerType DepthFirst -PreferredAppGroupType $preferedAppGroupType -MaxSessionLimit $maxLimit
        New-AzWvdRegistrationInfo -ResourceGroupName $ResourceGroupName -HostPoolName $hostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddDays(30).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
    }
    else {
        Write-Verbose "HostPool:'$hostPoolName' already exist."
    }
    $applicationGroupTest = Get-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($applicationGroupTest.count -eq 0) {
        Write-Verbose "Creating new ApplicationGroup:'$appGroupName' in resourcegroup: '$ResourceGroupName', under location: '$WVDLocation'"
        $hostPoolID = (Get-AzWvdHostPool -Name $hostPoolName -ResourceGroupName $ResourceGroupName).id
        New-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $ResourceGroupName -Location $WVDLocation -FriendlyName $friendlyName -HostPoolArmPath $hostPoolID -ApplicationGroupType $aplicationGroupType
        $appGroupID = (Get-AzWvdApplicationGroup -Name $appGroupName -ResourceGroupName $ResourceGroupName).id
        Update-AzWvdWorkspace -Name $workspaceName -ResourceGroupName $ResourceGroupName -ApplicationGroupReference $appGroupID
    }
    else {
        Write-Verbose "ApplicationGroup:'$appGroupName' already exist."
    }
    Write-Verbose "Assigning group '$WVDusersGroupName' to the Application Group '$appGroupName'"
    New-AzRoleAssignment -ObjectId $wvd_UsersGroup.ObjectID -RoleDefinitionName "Desktop Virtualization User" -ResourceName $appGroupName -ResourceGroupName $resourceGroupName -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'
}
#endregion

#region Section 2 VM deployment
throw 'Deploy Windows 10 multisession vm'
#endregion
$VerbosePreference = $verboseSettings