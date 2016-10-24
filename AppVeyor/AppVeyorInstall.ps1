#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor install script' -ForegroundColor Yellow

#---------------------------------# 
# Install NuGet                   # 
#---------------------------------# 
Write-Host 'Installing NuGet PackageProvide' 
$pkg = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
Write-Host "Installed NuGet version '$($pkg.version)'" 

#---------------------------------# 
# Install Modules                 # 
#---------------------------------# 
[version]$ScriptAnalyzerVersion = '1.8.0'
Write-Host 'Installing Script Analyzer' 
Install-Module -Name 'PSScriptAnalyzer' -Repository PSGallery -Force -ErrorAction Stop -MaximumVersion $ScriptAnalyzerVersion

Write-Host 'Installing Pester' 
Install-Module -Name 'Pester','xDSCResourceDesigner' -Repository PSGallery -Force -ErrorAction Stop

#---------------------------------# 
# Update PSModulePath             # 
#---------------------------------# 
Write-Host 'Updating PSModulePath for DSC resource testing'
$env:PSModulePath = $env:PSModulePath + ";" + "C:\projects"

#---------------------------------# 
# Validate                        # 
#---------------------------------# 
$RequiredModules = 'PSScriptAnalyzer','Pester','xDSCResourceDesigner'
$InstalledModules = Get-Module -Name $RequiredModules -ListAvailable
if ( ($InstalledModules.count -lt $RequiredModules.Count) -or ($Null -eq $InstalledModules)) { 
  throw "Required modules are missing."
} else {
  Write-Host 'All modules required found' -ForegroundColor Green
}