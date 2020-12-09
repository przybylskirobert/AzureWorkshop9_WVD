Throw "This is not a robust file"

#region Section 2 - Variables declaration
Write-Verbose "Section 2 - Variables declaration"
$verboseSettings = $VerbosePreference
$VerbosePreference = 'Continue'
$toolsPath = "C:\Tools"
$optimalizationScriptURL = 'https://github.com/przybylskirobert/Virtual-Desktop-Optimization-Tool/archive/master.zip'
$optimalizationScriptZIP = "$toolsPath\WVDOptimalization.zip"
$OptimalizationFolderName = "$toolsPath\" + [System.IO.Path]::GetFileNameWithoutExtension("$optimalizationScriptZIP")

#endregion


#region Section 2 - Optimization
Write-Verbose "Section 2 - Optimization"
Write-Verbose "Downloading '$optimalizationScriptURL' into '$optimalizationScriptZIP'"
Invoke-WebRequest -Uri $optimalizationScriptURL -OutFile $optimalizationScriptZIP
New-Item -ItemType Directory -Path "$OptimalizationFolderName"
Write-Verbose "Expanding Archive '$optimalizationScriptZIP ' into '$OptimalizationFolderName'"
Expand-Archive -LiteralPath $optimalizationScriptZIP -DestinationPath $OptimalizationFolderName
Set-Location "$OptimalizationFolderName\Virtual-Desktop-Optimization-Tool-master"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
.\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose

#endregion

#region Section 2 - Customize OS
Write-Verbose "Section 2 - Customize OS"
Write-Verbose "Disabling Windows updates"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
Write-Verbose "Configuring Time zone redirection"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f
Write-Verbose "Disabling Storage Sense"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 0 /f

#endregion

#region Section 2 - Finalization
Write-Verbose "Section 2 - Variables Finalization"
Set-Location c:\
Remove-Item -Path $toolsPath -Force
Write-Verbose "Starting Sysprep"
. $env:SystemRoot\system32\sysprep\sysprep.exe

#end region
$VerbosePreference = $verboseSettings
