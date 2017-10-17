enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTApplication
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$ShortName

    [DscProperty(Mandatory)]
    [string]$Version

    [DscProperty(Mandatory)]
    [string]$Publisher

    [DscProperty(Mandatory)]
    [string]$Language
    
    [DscProperty(Mandatory)]
    [string]$CommandLine
    
    [DscProperty(Mandatory)]
    [string]$WorkingDirectory
    
    [DscProperty(Mandatory)]
    [string]$ApplicationSourcePath
    
    [DscProperty(Mandatory)]
    [string]$TempLocation

    [DscProperty(Mandatory)]
    [string]$DestinationFolder
    
    [DscProperty(Mandatory)]
    [string]$Enabled

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.ApplicationSourcePath

        # Set file name based on name, version and type
        $filename = "$((Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator))_$($this.Version).zip"

        If ($this.Debug) { Invoke-Logger -Message "Download file: $filename" -Severity D -Category "cMDTApplication" -Type SET }

        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator).Split(".")[0]

        If ($this.Debug) { Invoke-Logger -Message "Folder name: $foldername" -Severity D -Category "cMDTApplication" -Type SET }

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.ApplicationSourcePath.Substring(0,2) -eq "\\"))
        { $targetdownload = "$($this.TempLocation)\$($filename)" }
        Else
        { $targetdownload = "$($this.ApplicationSourcePath)_$($this.Version).zip" ; $download = $False }
        If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }
        
        # Set temporary extraction folder name
        $extractfolder = "$($this.TempLocation)\$($foldername)"

        If ($this.Debug) { Invoke-Logger -Message "Extract folder: $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

        # Set reference file name to enable versioning
        $referencefile = "$($this.PSDrivePath)\Applications\$($this.DestinationFolder)\$((Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator)).version"

        If ($this.Debug) { Invoke-Logger -Message "Reference file: $referencefile" -Severity D -Category "cMDTApplication" -Type SET }

        # Determine if application should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {

            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTApplication" -Type SET }

            # Check if application already exist in MDT
            $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

            if ($present)
            {

                #  Upgrade existing application

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTApplication" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.ApplicationSourcePath)_$($this.Version).zip'" -Severity D -Category "cMDTApplication" -Type SET }

                    # Start download
                    Invoke-WebDownload -Source "$($this.ApplicationSourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target '$($this.PSDrivePath)\Applications\$($this.DestinationFolder)'" -Severity D -Category "cMDTApplication" -Type SET }

                # Expand archive to application folder in MDT
                Invoke-ExpandArchive -Source $targetdownload -Target "$($this.PSDrivePath)\Applications\$($this.DestinationFolder)"

                # If downloaded
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }

                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }
            }
            else
            {

                #  Import new application

                If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

                # Create path for new application import
                Invoke-CreatePath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTApplication" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.ApplicationSourcePath)_$($this.Version).zip'" -Severity D -Category "cMDTApplication" -Type SET }

                    # Start download of application
                    Invoke-WebDownload -Source "$($this.ApplicationSourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Expand archive
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Check if expanded folder exist
                $present = Invoke-TestPath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

                # If expanded folder does not exist
                If (-not($present)) { Write-Error "Cannot find path '$extractfolder' because it does not exist." ; Return }

                # If downloaded
                If ($download) {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }
                    
                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }

                # Call MDT import of new application
                $this.ImportApplication($extractfolder)

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Remove expanded folder after import
                Invoke-RemovePath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "New-ReferenceFile -Path $referencefile -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTApplication" -Type SET }

                # Create new versioning file
                New-ReferenceFile -Path $referencefile -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath
            }

            If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value $($this.Version)" -Severity D -Category "cMDTApplication" -Type SET }

            # Set versioning file content
            Set-Content -Path $referencefile -Value "$($this.Version)"
        }
        else
        {

            # Remove existing application

            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.name)' -Recurse -Levels 3 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

            # Remove application and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }
    }

    [bool] Test()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.ApplicationSourcePath

        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTApplication" -Type TEST }

        # Check if application already exists in MDT
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath 

        # If application exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {
            If ($this.Debug) { Invoke-Logger -Message "Compare-Version -Source '$($this.PSDrivePath)\Applications\$($this.DestinationFolder)\$($this.ApplicationSourcePath.Split($($separator))[-1]).version' -Target $($this.Version)" -Severity D -Category "cMDTApplication" -Type TEST }

            # Verify version against the reference file
            $match = Compare-Version -Source "$($this.PSDrivePath)\Applications\$($this.DestinationFolder)\$((Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator)).version" -Target $this.Version

            If ($this.Debug) { Invoke-Logger -Message "Match: $match" -Severity D -Category "cMDTApplication" -Type TEST }

            # If versioning file content do not match
            if (-not ($match))
            {
                If ($this.Debug) { Invoke-Logger -Message "$($this.Name) version has been updated on the pull server" -Severity D -Category "cMDTApplication" -Type TEST }
                Write-Verbose "$($this.Name) version has been updated on the pull server"
                $present = $false
            }
        }
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            If ($this.Debug) { Invoke-Logger -Message "Return $present" -Severity D -Category "cMDTApplication" -Type TEST }
            return $present
        }
        else
        {
            If ($this.Debug) { Invoke-Logger -Message "Return -not $present" -Severity D -Category "cMDTApplication" -Type TEST }
            return -not $present
        }
    }

    [cMDTApplication] Get()
    {
        return $this
    }

    [void] ImportApplication($Source)
    {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Import the required module MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        If ($this.Debug) { Invoke-Logger -Message "If (-not(Invoke-TestPath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)))" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Verify that the path for the application import exist
        If (-not(Invoke-TestPath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type FUNCTION }

            # Create folder path to prepare for application import
            Invoke-CreatePath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }

        If ($this.Debug) { Invoke-Logger -Message "Import-MDTApplication -Path $($this.Path) -Enable $($this.Enabled) -Name $($this.Name) -ShortName $($this.ShortName) -Version $($this.Version) -Publisher $($this.Publisher) -Language $($this.Language) -CommandLine $($this.CommandLine) -WorkingDirectory $($this.WorkingDirectory) -ApplicationSourcePath $($Source) -DestinationFolder $($this.DestinationFolder) -Verbose" -Severity D -Category "cMDTApplication" -Type FUNCTION }   

        # Initialize application import to MDT
        Import-MDTApplication -Path $this.Path -Enable $this.Enabled -Name $this.Name -ShortName $this.ShortName -Version $this.Version `
                              -Publisher $this.Publisher -Language $this.Language -CommandLine $this.CommandLine -WorkingDirectory $this.WorkingDirectory `                              -ApplicationSourcePath $Source -DestinationFolder $this.DestinationFolder -Verbose

    }
}
[DscResource()]
class cMDTApplicationBundle
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$BundleName

    [DscProperty(Mandatory)]
    [string[]]$BundledApplications

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [string]$Version = [string]::Empty
    
    [DscProperty()]
    [string]$Publisher = [string]::Empty

    [DscProperty()]
    [string]$Language = [string]::Empty

    [DscProperty()]
    [string]$Hide = $false

    [DscProperty()]
    [string]$Enable = $true

    [DscProperty()]
    [string]$Folder = 'Applications'

    [void] Set()
    {    
        
        # Call function to check if bundle exist
        $present           = $this.ApplicationBundleExists()

        # Call function to check if bundle needs to be updated
        $bundleNeedsUpdate = $this.ApplicationBundleNeedsUpdate()
        
        # Determine if bundle should be present or not
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false)
        {
            if ($bundleNeedsUpdate)
            {

                # Update bundle
                $this.UpdateApplicationBundle()
            }
            else
            {

                # Create bundle
                $this.CreateApplicationBundle()
            }
        }
        elseif ($this.Ensure -eq [ensure]::Absent -and $present -eq $true)
        {
            
            # Remove bundle
            $this.RemoveApplicationBundle()
        }
        
    }

    [bool] Test()
    {
        
        # Call function to check if bundle exist
        $present = $this.ApplicationBundleExists()

        # Return boolean from test method
        if ($this.Ensure -eq [ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTApplicationBundle] Get()
    {
        return $this
    }

    [bool] ApplicationBundleExists()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        # Check if bundle exist
        $bundle = Get-ChildItem "$($this.PSDriveName):" -Recurse | 
                    Where-Object {$_.Name -eq "$($this.BundleName)" -and $_.NodeType -eq 'Application'}

        if ($bundle)
        {

            # Check if bundle needs to be updated
            if ($this.ApplicationBundleNeedsUpdate())
            {
                return $false
            }
            return $true
        }
        return $false

    }

    [bool] ApplicationBundleNeedsUpdate()
    {

        # Import MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
    
        # Check if bundle exist
        $bundle = Get-ChildItem "$($this.PSDriveName):" -Recurse | 
                    Where-Object {$_.Name -eq "$($this.BundleName)" -and $_.NodeType -eq 'Application'}

        if (!$bundle)
        {
            return $false
        }

        # Get GUID:s from bundle
        $applicationGuids = $this.GetApplicationGuids()

        # Compare GUID:s to check if update is needed
        if ((Compare-Object $applicationGuids $bundle.Dependency) -ne $null) {return $true}

        # Verify bundle parameter properties
        if ($bundle.ShortName -ne $this.BundleName)            {return $true}
        if ($bundle.Version   -ne $this.Version)               {return $true}
        if ($bundle.Publisher -ne $this.Publisher)             {return $true}
        if ($bundle.Language  -ne $this.Language)              {return $true}
        if ($bundle.Hide      -ne $this.Hide.ToString())       {return $true}
        if ($bundle.Enable    -ne $this.Enable.ToString())     {return $true}
            
        return $false        
    }

    [void] CreateApplicationBundle()
    {

        # Import MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        # Set splatting parameters from input
        $importParams = @{
            Path        = "$($this.PSDriveName):\$($this.Folder)"
            Enable      = $this.Enable.ToString()
            Hide        = $this.Hide.ToString()
            Name        = $this.BundleName
            ShortName   = $this.BundleName
            DisplayName = $this.BundleName
            Version     = $this.Version
            Publisher   = $this.Publisher
            Language    = $this.Language
            Bundle      = $true
        }

        # Import MDT application
        Import-MDTApplication @importParams > $null

        # Define path to bundle in MDT
        $path = "$($this.PSDriveName):\$($this.Folder)\$($this.BundleName)"
        
        # Get GUID:s for bundle
        $applicationGuids = $this.GetApplicationGuids()

        # Set GUID:s to property for matching capabilities
        Set-ItemProperty -Path $path -Name Dependency -Value $applicationGuids

    }

    [void] UpdateApplicationBundle()
    {

        # Import MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        # Define path to bundle in MDT
        $path = "$($this.PSDriveName):\$($this.Folder)\$($this.BundleName)"

        # Define attributes to be verified
        $properties = @('Enable',
                        'Hide',
                        'ShortName',
                        'DisplayName',
                        'Version',
                        'Publisher',
                        'Language')
        
        # Loop through attributes and update accordingly
        foreach ($property in $properties)
        {
            if ($property -eq 'ShortName' -or $property -eq 'DisplayName')
            {
                Set-ItemProperty -Path "$path" -Name "$property" -Value "$($this.BundleName)"
            }
            else
            {
                Set-ItemProperty -Path "$path" -Name "$property" -Value "$($this.$property.ToString())"
            }
        }
        
        # Get GUID:s for bundle
        $applicationGuids = $this.GetApplicationGuids()

        # Set GUID:s to property for matching capabilities
        Set-ItemProperty -Path $path -Name Dependency -Value $applicationGuids
    }

    [void] RemoveApplicationBundle()
    {
        Import-MicrosoftDeploymentToolkitModule
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        $path = "$($this.PSDriveName):\$($this.Folder)\$($this.BundleName)"
        Remove-Item -Path $path
    }
    [string[]] GetApplicationGuids()
    {
        Import-MicrosoftDeploymentToolkitModule
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        [string[]]$applicationGuids = @()
        foreach ($application in $this.BundledApplications)
        {
            $applicationGuid = Get-ChildItem "$($this.PSDriveName):" -Recurse | 
                        Where-Object {$_.Name -eq $application -and $_.NodeType -eq 'Application'} | 
                        Select-Object -ExpandProperty guid
            if ($applicationGuid)
            {
                $applicationguids += $applicationGuid
            }
        }
        return $applicationGuids
    }
    
}
[DscResource()]
class cMDTBootstrapIni
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty()]
    [string]$Content

    [void] Set()
    {

        # Check if defined as present
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # If set to present set content according to contract
            $this.SetContent()
        }
        else
        {
            # If set to absent revert to default content
            $this.SetDefaultContent()
        }
    }

    [bool] Test()
    {
        # Call function to test file content according to contract
        $present = $this.TestFileContent()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTBootstrapIni] Get()
    {
        return $this
    }

    [bool] TestFileContent()
    {
        $present = $false

        # Import existing file content
        $existingConfiguration = Get-Content -Path $this.Path -Raw #-Encoding UTF8

        # Match against content from contract
        if ($existingConfiguration -eq $this.Content.Replace("`n","`r`n"))
        {
            $present = $true   
        }

        # Return state
        return $present
    }

    [void] SetContent()
    {
        # Set new file content
        Set-Content -Path $this.Path -Value $this.Content.Replace("`n","`r`n") -NoNewline -Force #-Encoding UTF8 
    }
    
    [void] SetDefaultContent()
    {
        # Set default content
        $defaultContent = @"
[Settings]
Priority=Default

[Default]

"@
        Set-Content -Path $this.Path -Value $defaultContent -NoNewline -Force #-Encoding UTF8 
    }
}
[DscResource()]
class cMDTCustomize
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    [DscProperty(Mandatory)]
    [string]$Version

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$Path
    
    [DscProperty(Mandatory)]
    [string]$SourcePath

    [DscProperty(Mandatory)]
    [string]$TempLocation

    [bool]$Protected

    [DscProperty(NotConfigurable)]
    [string]$Directory

    [void] Set()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath   

        # Set file name basen on name and version
        $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator))_$($this.Version).zip"

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
        { $targetdownload = "$($this.TempLocation)\$($filename)" }
        Else
        { $targetdownload = "$($this.SourcePath)_$($this.Version).zip" ; $download = $False }

        # Set extraction folder name
        $extractfolder = "$($this.path)\$($this.name)"

        # Set reference file name to enable versioning
        $referencefile = "$($this.Path)\$($this.name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"

        # Determine if customization should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {
            
            # Check if customization already exist in MDT
            $present = Invoke-TestPath -Path "$($this.path)\$($this.name)"

            if ($present)
            {
                #  Upgrade existing customization

                # If customization must be downloaded before imported
                If ($download)
                {
                    # Start download of customization
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                # Check if protected mode has been defined
                if (-not $this.Protected)
                {
                    # Check if reference file exist
                    $present = Invoke-TestPath -Path $referencefile

                    # If it exist remove the reference file
                    If ($present) { Invoke-RemovePath -Path $referencefile }
                }

                # Expand archive to folder in MDT
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder -Verbose

                # If downloaded, remove downloaded archive after expansion
                If ($download) { Invoke-RemovePath -Path $targetdownload }

                # If protected mode has been defined create a new reference file
                If ($this.Protected) { New-ReferenceFile -Path $referencefile }
            }
            else
            {

                #  Import new customization

                # If customization must be downloaded before imported
                If ($download)
                {
                    # Start download of customization
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                # Expand archive to folder in MDT
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder -Verbose

                # If downloaded, remove downloaded archive after expansion
                If ($download) { Invoke-RemovePath -Path $targetdownload }

                # Create a new reference file
                New-ReferenceFile -Path $referencefile 
            }

            # Set versioning file content
            Set-Content -Path $referencefile -Value "$($this.Version)"
        }
        else
        {
            # Remove customization and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Verbose
        }
    }

    [bool] Test()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        # Check if customization exist in MDT
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)"

        # If customization exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {
            # Verify existence of reference file
            If (Test-Path -Path "$($this.Path)\$($this.name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version" -ErrorAction Ignore)
            {
                # Verify customization version against the reference file
                $match = Compare-Version -Source "$($this.Path)\$($this.name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version" -Target $this.Version

                # If versioning file content do not match
                if (-not ($match))
                {

                    Write-Verbose "$($this.Name) version has been updated on the pull server"
                    $present = $false
                }
            }
            else
            {
                $present = $false
            }
        }

        # If customization exist, should be absent but defined as protected
        if (($present) -and ($this.Protected) -and ($this.ensure -eq [Ensure]::Absent))
        {            Write-Verbose "Folder protection override mode defined"            Write-Verbose "$($this.Name) folder will not be removed"            return $true
        }
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTCustomize] Get()
    {
        return $this
    }
}
[DscResource()]
class cMDTCustomSettingsIni
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty()]
    [string]$Content

    [void] Set()
    {
        
        # Check if defined as present
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # If set to present set content according to contract
            $this.SetContent()
        }
        else
        {
            # If set to absent revert to default content
            $this.SetDefaultContent()
        }
    }

    [bool] Test()
    {

        # Call function to test file content according to contract
        $present = $this.TestFileContent()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTCustomSettingsIni] Get()
    {
        return $this
    }

    [bool] TestFileContent()
    {
        $present = $false

        # Import existing file content
        $existingConfiguration = Get-Content -Path $this.Path -Raw #-Encoding UTF8

        # Match against content from contract
        if ($existingConfiguration -eq $this.Content.Replace("`n","`r`n"))
        {
            $present = $true   
        }

        return $present
    }

    [void] SetContent()
    {
        # Set new file content
        Set-Content -Path $this.Path -Value $this.Content.Replace("`n","`r`n") -NoNewline -Force #-Encoding UTF8
    }
    
    [void] SetDefaultContent()
    {
        # Set default content
        $defaultContent = @"
[Settings]
Priority=Default
Properties=MyCustomProperty

[Default]
OSInstall=Y
SkipCapture=YES
SkipAdminPassword=NO
SkipProductKey=YES

"@
        Set-Content -Path $this.Path -Value $defaultContent -NoNewline -Force #-Encoding UTF8
    }
}
[DscResource()]
class cMDTDirectory
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [string]$PSDriveName

    [DscProperty()]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {
        
        # Determine present/absent
        if ($this.ensure -eq [Ensure]::Present)
        {
            # If present create path
            $this.CreateDirectory()
        }
        else
        {
            # Verify if local path or PSDrive
            if (($this.PSDrivePath) -and ($this.PSDriveName))
            {
                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.Name)' -Recurse -Levels 4 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDirectory" -Type SET }

                # Remove and traverse folder path where empty
                Invoke-RemovePath -Path "$($this.path)\$($this.Name)" -Recurse -Levels 4 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
            }
            Else
            {
                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.Name)' -Recurse -Levels 4 -Verbose" -Severity D -Category "cMDTDirectory" -Type SET }

                # Remove and traverse folder path where empty
                Invoke-RemovePath -Path "$($this.path)\$($this.Name)" -Recurse -Levels 4 -Verbose
            }
        }
    }

    [bool] Test()
    {

        # Verify if local path or PSDrive
        if (($this.PSDrivePath) -and ($this.PSDriveName))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.Name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDirectory" -Type TEST }

            # Verify if PSDrive path exist
            $present = Invoke-TestPath -Path "$($this.path)\$($this.Name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDirectory" -Type TEST }
        }
        Else
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.Name)' -Verbose" -Severity D -Category "cMDTDirectory" -Type TEST }

            # Verify if local path exist
            $present = Invoke-TestPath -Path "$($this.path)\$($this.Name)" -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDirectory" -Type TEST }
        }
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTDirectory] Get()
    {
        return $this
    }

    [void] CreateDirectory()
    {

        # Verify if local path or PSDrive
        if (($this.PSDrivePath) -and ($this.PSDriveName))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path '$($this.path)\$($this.Name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDirectory" -Type FUNCTION }

            # Create PSDrive path
            $present = Invoke-CreatePath -Path "$($this.path)\$($this.Name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDirectory" -Type FUNCTION }
        }
        Else
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path '$($this.path)\$($this.Name)' -Verbose" -Severity D -Category "cMDTDirectory" -Type FUNCTION }

            # Create local path
            Invoke-CreatePath -Path "$($this.path)\$($this.Name)" -Verbose
        }

    }
}
[DscResource()]
class cMDTDriver
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    [DscProperty(Mandatory)]
    [string]$Version

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Mandatory)]
    [string]$Enabled
    
    [DscProperty(Mandatory)]
    [string]$Comment
    
    [DscProperty(Mandatory)]
    [string]$SourcePath

    [DscProperty(Mandatory)]
    [string]$TempLocation

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        # Set file name based on name, version and type
        $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator))_$($this.Version).zip"

        If ($this.Debug) { Invoke-Logger -Message "Download file: $filename" -Severity D -Category "cMDTDriver" -Type SET }

        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.SourcePath -Separator $separator).Split(".")[0]

        If ($this.Debug) { Invoke-Logger -Message "Folder name: $foldername" -Severity D -Category "cMDTDriver" -Type SET }

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
        { $targetdownload = "$($this.TempLocation)\$($filename)" }
        Else
        { $targetdownload = "$($this.SourcePath)_$($this.Version).zip" ; $download = $False }
        If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

        # Set temporary extraction folder name
        $extractfolder = "$($this.TempLocation)\$($foldername)"

        If ($this.Debug) { Invoke-Logger -Message "Extract folder: $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

        # Set reference file name to enable versioning
        $referencefile = "$($this.PSDrivePath)\Out-of-Box Drivers\$($($this.Path.Split("\")[-2]).Replace(' ',''))$($($this.Path.Split("\")[-1]).Replace(' ',''))$($($this.Name).Replace(' ',''))$($this.SourcePath.Split($separator)[-1]).version"

        If ($this.Debug) { Invoke-Logger -Message "Reference file: $referencefile" -Severity D -Category "cMDTDriver" -Type SET }

        # Determine if driver should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {
            
            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTDriver" -Type SET }

            # Check if driver already exist in MDT
            $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

            if ($present)
            {
                #  Upgrade existing driver

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTDriver" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).zip' -Target $targetdownload -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

                    # Start download
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }
                
                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Expand archive
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Check if expanded folder exist
                $present = Invoke-TestPath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                # If expanded folder does not exist
                If (-not($present)) { Write-Error "Cannot find path '$extractfolder' because it does not exist." ; Return }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

                # Remove current version
                Invoke-RemovePath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

                # If downloaded
                If ($download) {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }

                # Call MDT import of new driver
                $this.ImportDriver($extractfolder)

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Remove expanded folder after import
                Invoke-RemovePath -Path $extractfolder
            }
            else
            {

                #  Import new driver

                If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

                # Create path for new driver import
                Invoke-CreatePath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTDriver" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).zip' -Target $targetdownload -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

                    # Start download
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }
                
                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Expand archive
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Check if expanded folder exist
                $present = Invoke-TestPath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                # If expanded folder does not exist
                If (-not($present)) { Write-Error "Cannot find path '$extractfolder' because it does not exist." ; Return }

                # If downloaded
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }

                # Call MDT import of new driver
                $this.ImportDriver($extractfolder)

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Remove expanded folder after import
                Invoke-RemovePath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "New-ReferenceFile -Path $referencefile" -Severity D -Category "cMDTDriver" -Type SET }

                # Create new versioning file
                New-ReferenceFile -Path $referencefile
            }

            If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value '$($this.Version)'" -Severity D -Category "cMDTDriver" -Type SET }

            # Set versioning file content
            Set-Content -Path $referencefile -Value "$($this.Version)"
        }
        else
        {
            # Remove existing driver
            
            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.name)' -Recurse -Levels 3 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

            # Remove application and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $referencefile" -Severity D -Category "cMDTDriver" -Type SET }

            # Remove reference file
            Invoke-RemovePath -Path $referencefile
        }
    }

    [bool] Test()
    {
        
        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTDriver" -Type TEST }

        # Check if driver already exists in MDT
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath 
        
        # If driver exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {

            If ($this.Debug) { Invoke-Logger -Message "Compare-Version -Source '$($this.PSDrivePath)\Out-of-Box Drivers\$($($this.Path.Split('\')[-2]).Replace(' ',''))$($($this.Path.Split('\')[-1]).Replace(' ',''))$($($this.Name).Replace(' ',''))$($this.SourcePath.Split($separator)[-1]).version' -Target $($this.Version)" -Severity D -Category "cMDTDriver" -Type TEST }

            # Verify version against the reference file
            $match = Compare-Version -Source "$($this.PSDrivePath)\Out-of-Box Drivers\$($($this.Path.Split("\")[-2]).Replace(' ',''))$($($this.Path.Split("\")[-1]).Replace(' ',''))$($($this.Name).Replace(' ',''))$($this.SourcePath.Split($separator)[-1]).version" -Target $this.Version

            If ($this.Debug) { Invoke-Logger -Message "Match: $match" -Severity D -Category "cMDTDriver" -Type TEST }

            # If versioning file content do not match
            if (-not ($match))
            {
                Write-Verbose "$($this.Name) version has been updated on the pull server"
                $present = $false
            }
        }
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTDriver] Get()
    {
        return $this
    }

    [void] ImportDriver($Driver)
    {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Import the required module MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        If ($this.Debug) { Invoke-Logger -Message "New-Item -Path $($this.Path) -enable $($this.Enabled) -Name $($this.Name) -Comments $($this.Comment) -ItemType 'folder' –Verbose" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Create path for the driver
        New-Item -Path $this.Path -enable $this.Enabled -Name $this.Name -Comments $this.Comment -ItemType "folder" –Verbose

        If ($this.Debug) { Invoke-Logger -Message "Import-MDTDriver -Path '$($this.path)\$($this.name)' -SourcePath $Driver -ImportDuplicates -Verbose" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Initialize driver import to MDT
        Import-MDTDriver -Path "$($this.path)\$($this.name)" -SourcePath $Driver -ImportDuplicates -Verbose

    }
}
[DscResource()]
class cMDTMonitorService
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [ValidateSet('Yes')]
    [DscProperty(Key)] 
    [ValidateNotNullorEmpty()]
    [String] $IsSingleInstance = 'Yes'

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty(Mandatory)]
    [string]$MonitorHost

    [void] Set()
    {

        # Check if monitor service is enabled
        $present = $this.MDTMonitorServiceIsEnabled()
        
        # Should monitor service be enabled
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false)
        {

            # Enable monitor service
            $this.EnableMDTMonitorService()            
        }
        elseif ($this.Ensure -eq [ensure]::Absent -and $present -eq $true)
        {

            # Disable monitor service
            $this.DisableMDTMonitorService()
        }
        
    }

    [bool] Test()
    {
        
        # Check if monitor service is enabled
        $present = $this.MDTMonitorServiceIsEnabled()

        # Return boolean from test method
        if ($this.Ensure -eq [ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTMonitorService] Get()
    {
        return $this
    }

    [bool] MDTMonitorServiceIsEnabled()
    {
    
        # Check if monitor service is started  
        try
        {
            $service = Get-Service MDT_Monitor -ErrorAction Stop
            if ($service.Status -ne 'Running')
            {
                return $false
            }
        }
        catch 
        {
            return $false
        }

        # Check if firewall ports for monitoring is opened
        if (!(Test-NetConnection -Port 9800 -ComputerName localhost -InformationLevel Quiet))
        {
            return $false
        }
        if (!(Test-NetConnection -Port 9801 -ComputerName localhost -InformationLevel Quiet))
        {
            return $false
        }

        try
        {

            # Get firewall rule for monitor service
            $rule = Get-NetFirewallRule -DisplayName 'MDT Monitor' -ErrorAction Stop

            # Get ports from firewall rule
            $ports = $rule | Get-NetFirewallPortFilter

            # Check if ports are defined in rule
            if (!($ports.LocalPort.Contains('9800') -and $ports.LocalPort.Contains('9801')))
            {
                return $false
            }
        }
        catch 
        {
            return $false
        }
        return $true
    }

    [void] EnableMDTMonitorService()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        # Enable monitor service
        Enable-MDTMonitorService -EventPort 9800 -DataPort 9801

        # Define host and ports
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorHost -Value $this.MonitorHost
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorEventPort -Value "9800"
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorDataPort -Value "9801"
       
    }

    [void] DisableMDTMonitorService()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Enable monitor service
        Disable-MDTMonitorService

        # Remove host and ports
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorHost -Value ""
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorEventPort -Value ""
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorDataPort -Value ""
    }
    
}
[DscResource()]
class cMDTOperatingSystem
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty()]
    [string]$Version

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$SourcePath

    [DscProperty(Mandatory)]
    [string]$TempLocation

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {

        # Determine versioning type; checksum or static version
        [bool]$Hash = $False
        If (-not ($this.version))
        { $Hash = $True }

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        $filename = $null

        # Set file name based on versioning type
        If ($Hash)
        {
            $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).wim"
        }
        Else
        {
            $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator))_$($this.Version).wim"
        }
        If ($this.Debug) { Invoke-Logger -Message "Download file: $filename" -Severity D -Category "cMDTOperatingSystem" -Type SET }
        
        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.SourcePath -Separator $separator).Split(".")[0]

        If ($this.Debug) { Invoke-Logger -Message "Folder name: $foldername" -Severity D -Category "cMDTOperatingSystem" -Type SET }

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
        {
            $targetdownload = "$($this.TempLocation)\$($filename)"

            If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            $targetdownloadref = "$($this.TempLocation)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"

            If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }
        }
        Else
        {
            If ($this.Debug) { Invoke-Logger -Message "Hash: $Hash" -Severity D -Category "cMDTOperatingSystem" -Type SET }
            If ($Hash)
            {
                $targetdownload = "$($this.SourcePath).wim"
                If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                $targetdownloadref = "$($this.SourcePath).version"
                If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }
            }
            Else
            {
                $targetdownload = "$($this.SourcePath)_$($this.Version).wim"
                If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                $targetdownloadref = "$($this.SourcePath)_$($this.Version).version"
                If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }
            }
            $download = $False
        }

        # Set reference file name to enable versioning
        $referencefile = "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"

        If ($this.Debug) { Invoke-Logger -Message "Reference file: $referencefile" -Severity D -Category "cMDTOperatingSystem" -Type SET }

        # Set temporary extraction folder name
        $extractfolder = "$($this.TempLocation)\$($foldername)"

        If ($this.Debug) { Invoke-Logger -Message "Extract folder: $extractfolder" -Severity D -Category "cMDTOperatingSystem" -Type SET }

        # Determine if OS should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {

            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # Check if OS already exist in MDT
            $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)"

            if ($present)
            {

                # Upgrade existing OS

                If ($Hash)
                {
                    
                    # If checksum automatic update defined

                    If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                    # If file must be downloaded before imported
                    If ($download)
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Start download of WIM
                        Invoke-WebDownload -Source "$($this.SourcePath).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).version' -Target $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Start download of checksum file
                        Invoke-WebDownload -Source "$($this.SourcePath).version" -Target $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download of checksum was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownloadref' because it does not exist." ; Return }

                    }
                    Else
                    {

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if WIM image can be found on source
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If image can not be found
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                    }
                }
                Else
                {

                    # If versioning update was defined

                    # If file must be downloaded before imported
                    If ($download)
                    {

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Start download of WIM
                        Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                    }
                }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                
                # Remove existing OS file
                Invoke-RemovePath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Verbose

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Test if removal was successfull
                $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)"

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # If removal was unsuccessfull
                If ($present) { Write-Error "Could not remove path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)'." ; Return }

                # Define new file names for import. Needed to keep names intact in MDT when not performing a new import.
                $oldname = $null
                $newname = $null
                If (-not ($Hash))
                {
                    $oldname = $targetdownload
                    $newname = $targetdownload.Replace("_$($this.Version)","")
                }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Copy-Item $targetdownload -Destination '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Force -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                    # Copy WIM file to MDT storage location
                    Copy-Item $targetdownload -Destination "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Force -Verbose
                }
                Else
                {
                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename file for import
                        Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                    If ($Hash)
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Copy-Item $targetdownload -Destination '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Force -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Copy WIM file to MDT storage location
                        Copy-Item $targetdownload -Destination "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Force -Verbose
                    }
                    Else
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Copy-Item $newname -Destination '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Force -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Copy renamed WIM file to MDT storage location
                        Copy-Item $newname -Destination "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Force -Verbose
                    }
                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename source file to back original name
                        Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                }

                If ($Hash)
                {

                    # Get versioning from downloaded checksum
                    $this.version = Get-Content -Path $targetdownloadref

                    If ($this.Debug) { Invoke-Logger -Message "Version: $($this.version)" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                }

                If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value '$($this.Version)' -Verbose:$($false)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Set versioning content to reference file
                Set-Content -Path $referencefile -Value "$($this.Version)" -Verbose:$false
            }
            else
            {

                # Import new OS

                If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path '$($this.Path)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Create path for new OS import
                Invoke-CreatePath -Path "$($this.Path)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
                
                # Define new file names for import. Needed to keep names intact in MDT when not performing a new import.
                $oldname = $null
                $newname = $null
                If (-not ($Hash))
                {
                    $oldname = $targetdownload
                    $newname = $targetdownload.Replace("_$($this.Version)","")
                }

                # If file must be downloaded before imported
                If ($download)
                {

                    # If file must be downloaded before imported

                    If ($this.Debug) { Invoke-Logger -Message "Hash: $Hash" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                    If ($Hash)
                    {
                        
                        # If checksum update was defined

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Download WIm file
                        Invoke-WebDownload -Source "$($this.SourcePath).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).version' -Target $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Download checksum file
                        Invoke-WebDownload -Source "$($this.SourcePath).version" -Target $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownloadref' because it does not exist." ; Return }

                    }
                    Else
                    {

                        # If versioning update was defined

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Download WIM file
                        Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                    }

                    # Call function to import OS
                    $this.ImportOperatingSystem($targetdownload)
                }
                Else
                {

                    # If file must not be downloaded before imported

                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename file for import
                        Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                    If ($Hash)
                    {

                        # Call function to import OS
                        $this.ImportOperatingSystem($targetdownload)
                    }
                    Else
                    {

                        # Call function to import OS
                        $this.ImportOperatingSystem($newname)
                    }
                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename file after import
                        Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                }

                If ($this.Debug) { Invoke-Logger -Message "New-ReferenceFile -Path $referencefile -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Create new reference file for versioning
                New-ReferenceFile -Path $referencefile -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath

                If ($Hash)
                {

                    # Get checksum from downloaded file
                    $this.version = Get-Content -Path $targetdownloadref

                    If ($this.Debug) { Invoke-Logger -Message "Version: $($this.version)" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                }

                If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value '$($this.Version)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Set versioning file content
                Set-Content -Path $referencefile -Value "$($this.Version)"
            }
        }
        else
        {

            # Remove existing OS

            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.Path)' -Recurse -Levels 4 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # Remove OS recursively from MDT
            Invoke-RemovePath -Path "$($this.Path)" -Recurse -Levels 4 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # Test if renmoval was successfull
            $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)"

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # If removal was not successfull
            If ($present) { Write-Error "Cannot find path '$($this.PSDrivePath)\Operating Systems\$($this.Name)' because it does not exist." }

        }

    }

    [bool] Test()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        # Determine if checksum or manual versioning update was defined
        If (-not ($this.version))
        {

            # Determine versioning file must be downloaded
            [bool]$download = $True
            If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
            {
                $targetdownloadref = "$($this.TempLocation)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"
            }
            Else
            {
                $targetdownloadref = "$($this.SourcePath).version"
                $download = $False
            }
            If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

            If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTOperatingSystem" -Type TEST }
            If ($download)
            {
                If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).version' -Target $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

                # Download versioning file
                Invoke-WebDownload -Source "$($this.SourcePath).version" -Target $targetdownloadref

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

                # Test if download was successfull
                $present = Invoke-TestPath -Path $targetdownloadref
                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

                # If download was not successfull
                If (-not($present)) { Write-Error "Cannot find path '$targetdownloadref' because it does not exist." ; Exit }
            }

            # Get content from downloaded versioning file
            $this.version = Get-Content -Path $targetdownloadref

            If ($this.Debug) { Invoke-Logger -Message "Version: $($this.version)" -Severity D -Category "cMDTOperatingSystem" -Type TEST }
        }

        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).wim'" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

        # Test if OS file already exist in MDT
        $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).wim"

        # If OS exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {
            If ($this.Debug) { Invoke-Logger -Message "Compare-Version -Source '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version' -Target $($this.Version)" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

            # Verify content from server side versioning file against local reference file
            $match = Compare-Version -Source "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version" -Target $this.Version

            If ($this.Debug) { Invoke-Logger -Message "Match: $match" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

            if (-not ($match))
            {

                # If version does not match
                Write-Verbose "$($this.Name) version has been updated on the pull server"
                $present = $false
            }
        }
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTOperatingSystem] Get()
    {
        return $this
    }

    [void] ImportOperatingSystem($OperatingSystem)
    {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

        # Import the MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        # Verify that the path for the application import exist
        If (-not(Invoke-TestPath -Path $this.Path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.Path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

            # Create folder path to prepare for OS import
            Invoke-CreatePath -Path $this.Path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }

        Try
        {
            
            $ErrorActionPreference = "Stop"

            If ($this.Debug) { Invoke-Logger -Message "Import-MDTOperatingSystem -Path $($this.Path) -SourceFile $OperatingSystem -DestinationFolder $($this.Name) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

            # Start import of OS file
            Import-MDTOperatingSystem -Path $this.Path -SourceFile $OperatingSystem -DestinationFolder $this.Name -Verbose

            $ErrorActionPreference = "Continue"
        }
            Catch [Microsoft.Management.Infrastructure.CimException]
            {
                If ($_.FullyQualifiedErrorId -notlike "*ItemAlreadyExists*")
                {
                    throw $_
                }
            }
            Finally
            {
                
            }
        }
}
[DscResource()]
class cMDTPersistentDrive
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [string]$Description

    [DscProperty(Mandatory)]
    [string]$NetworkPath

    [void] Set()
    {

        # Determine present/absent
        if ($this.ensure -eq [Ensure]::Present)
        {
            
            # If present create drive
            $this.CreateDirectory()
        }
        else
        {

            # If absent remove drive
            $this.RemoveDirectory()
        }
    }

    [bool] Test()
    {

        # Check if persistent drive exist
        $present = $this.TestDirectoryPath()
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTPersistentDrive] Get()
    {
        return $this
    }

    [bool] TestDirectoryPath()
    {
        $present = $false

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Check if persistent drive exist
        if (Test-Path -Path $this.Path -PathType Container -ErrorAction Ignore)
        {
            $mdtShares = (GET-MDTPersistentDrive -ErrorAction SilentlyContinue)
            If ($mdtShares)
            {
                ForEach ($share in $mdtShares)
                {
                    If ($share.Name -eq $this.Name)
                    {
                        $present = $true
                    }
                }
            } 
        }

        return $present
    }

    [void] CreateDirectory()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.Name -PSProvider "MDTProvider" -Root $this.Path -Description $this.Description -NetworkPath $this.NetworkPath -Verbose:$false | `        # Create MDT persistent drive        Add-MDTPersistentDrive -Verbose

    }

    [void] RemoveDirectory()
    {
        
        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        Write-Verbose -Message "Removing MDTPersistentDrive $($this.Name)"

        # Create PSDrive
        New-PSDrive -Name $this.Name -PSProvider "MDTProvider" -Root $this.Path -Description $this.Description -NetworkPath $this.NetworkPath -Verbose:$false | `        # Remove MDT persistent drive        Remove-MDTPersistentDrive -Verbose
    }
}
[DscResource()]
class cMDTPreReqs
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    [DscProperty(Key)]
    [string]$DownloadPath

    [DscProperty(Mandatory)] 
    [hashtable]$Prerequisites
    
    [void] Set()
    {
        Write-Verbose "Starting Set MDT PreReqs..."

        if ($this.ensure -eq [Ensure]::Present)
        {
            $present = $this.TestDownloadPath()

            if ($present){
                Write-Verbose "   Download folder present!"
            }
            else{
                New-Item -Path $this.DownloadPath -ItemType Directory -Force
            }

            [string]$separator = ""
            If ($this.DownloadPath -like "*/*")
            { $separator = "/" }
            Else
            { $separator = "\" }
            
            #Set all files:               
            ForEach ($file in $this.Prerequisites)
            {
                if($file.MDT){                     
                    if(Test-Path -Path "$($this.DownloadPath)\Microsoft Deployment Toolkit"){
                        Write-Verbose "   MDT already present!"
                    }
                    Else{
                        Write-Verbose "   Creating MDT folder..."
                        New-Item -Path "$($this.DownloadPath)\Microsoft Deployment Toolkit" -ItemType Directory -Force
                        $this.WebClientDownload($file.MDT, "$($this.DownloadPath)\Microsoft Deployment Toolkit\MicrosoftDeploymentToolkit2013_x64.msi")
                    }
                }

                if($file.ADK){                     
                    if(Test-Path -Path "$($this.DownloadPath)\Windows Assessment and Deployment Kit"){
                        Write-Verbose "   ADK folder already present!"
                    }
                    Else{
                        Write-Verbose "   Creating ADK folder..."
                        New-Item -Path "$($this.DownloadPath)\Windows Assessment and Deployment Kit" -ItemType Directory -Force
                        $this.WebClientDownload($file.ADK,"$($this.DownloadPath)\Windows Assessment and Deployment Kit\adksetup.exe")
                        #Run setup to prepp files...
                    }
                }

                <#
                if($file.SQL){                     
                    if(Test-Path -Path "$($this.DownloadPath)\Microsoft SQL Server 2014 Express"){
                        Write-Verbose "   SQL folder already present!"
                    }
                    Else{
                        Write-Verbose "   Creating SQL folder..."
                        New-Item -Path "$($this.DownloadPath)\Microsoft SQL Server 2014 Express" -ItemType Directory -Force
                        $this.WebClientDownload($file.SQL,"$($this.DownloadPath)\Microsoft SQL Server 2014 Express\SQLEXPR_x64_ENU.exe")
                    }
                }
                #>

                if(Test-Path -Path "$($this.DownloadPath)\Community"){
                    Write-Verbose "   Community folder already present!"
                }
                Else{
                    Write-Verbose "   Creating Community folder..."
                    New-Item -Path "$($this.DownloadPath)\Community" -ItemType Directory -Force
                    New-Item -Path "$($this.DownloadPath)\Community\Scripts" -ItemType Directory -Force
                    New-Item -Path "$($this.DownloadPath)\Community\Control" -ItemType Directory -Force
                    New-Item -Path "$($this.DownloadPath)\Community\PEextraFiles" -ItemType Directory -Force
                }

                if($file.C01){
                    #ToDo: Need test for all files...                  
                    $this.WebClientDownload($file.C01,"$($this.DownloadPath)\Community\modelalias.zip")
                    $this.ExtractFile("$($this.DownloadPath)\Community\modelalias.zip","$($this.DownloadPath)\Community")
                    Move-Item "$($this.DownloadPath)\Community\ModelAlias\ModelAliasExit.vbs" "$($this.DownloadPath)\Community\Scripts"
                    Remove-Item -Path "$($this.DownloadPath)\Community\ModelAlias" -Force
                    Remove-Item -Path "$($this.DownloadPath)\Community\modelalias.zip" -Force
                }
            }
            
            
        }
        else
        {
            $this.RemoveDirectory("")
        }

        Write-Verbose "MDT PreReqs set completed!"
    }

    [bool] Test()
    {
        Write-Verbose "Testing MDT PreReqs..."
        $present = $this.TestDownloadPath()

        if ($this.ensure -eq [Ensure]::Present)
        {            
            Write-Verbose "   Testing for download path.."            
            if($present){
                Write-Verbose "   Download path found!"}            
            Else{
                Write-Verbose "   Download path not found!"
                return $present }

            ForEach ($File in $this.Prerequisites)
            {
               if($file.MDT){
                 Write-Verbose "   Testing for MDT..."                
                 $present = (Test-Path -Path "$($this.DownloadPath)\Microsoft Deployment Toolkit\MicrosoftDeploymentToolkit2013_x64.msi")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}
               }
               
               if($file.ADK){
                 Write-Verbose "   Testing for ADK..."                 
                 $present = (Test-Path -Path "$($this.DownloadPath)\Windows Assessment and Deployment Kit\adksetup.exe")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}   
               }

               <#
               if($file.SQL){
                 Write-Verbose "   Testing for SQL..."                 
                 $present = (Test-Path -Path "$($this.DownloadPath)\Microsoft SQL Server 2014 Express\SQLEXPR_x64_ENU.exe")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}   
               }
               #>

               if($file.C01){
                 Write-Verbose "   Testing for Community Script: ModelAlias.vbs"                 
                 $present = (Test-Path -Path "$($this.DownloadPath)\Community\Scripts\ModelAliasExit.vbs")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}   
               }
            }
        }
        else{
            if ($Present){
               $present = $false 
            }
            else{
               $present = $true 
            }
        }

        Write-Verbose "Test completed!"
        return $present
    }

    [cMDTPreReqs] Get()
    {
        return $this
    }

    [bool] TestDownloadPath()
    {
        $present = $false

        if (Test-Path -Path $this.DownloadPath -ErrorAction Ignore)
        {
            $present = $true
        }        

        return $present
    }

    [bool] VerifyFiles()
    {

        [bool]$match = $false

        if (Get-ChildItem -Path $this.DownloadPath -Recurse)
        {
            #ForEach File, test...
            $match = $true
        }
        
        return $match
    }

    [void] WebClientDownload($Source,$Target)
    {
        $WebClient = New-Object System.Net.WebClient
        Write-Verbose "      Downloading file $($Source)"
        Write-Verbose "      Downloading to $($Target)"
        $WebClient.DownloadFile($Source, $Target)
    }

    [void] ExtractFile($Source,$Target)
    {
        Write-Verbose "      Extracting file to $($Target)"
        Expand-Archive $Source -DestinationPath $Target -Force
    }

    [void] CleanTempDirectory($Object)
    {

        Remove-Item -Path $Object -Force -Recurse -Verbose:$False
    }

    [void] RemoveDirectory($referencefile = "")
    {
        Remove-Item -Path $this.DownloadPath -Force -Verbose     
    }

    [void] RemoveReferenceFile($File)
    {
        Remove-Item -Path $File -Force -Verbose:$False
    }
}
[DscResource()]
class cMDTTaskSequence
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [string]$OperatingSystemPath

    [DscProperty()]
    [string]$WIMFileName

    [DscProperty(Mandatory)]
    [string]$ID

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [void] Set()
    {

        # Determine present/absent
        if ($this.ensure -eq [Ensure]::Present)
        {

            # Call function to import task sequence
            $this.ImportTaskSequence()
        }
        else
        {

            # Remove path recursively
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }
    }

    [bool] Test()
    {

        # Test if path exist
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath 
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTTaskSequence] Get()
    {
        return $this
    }

    [void] ImportTaskSequence()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        $OperatingSystemFile = $null

        If ($this.OperatingSystemPath)
        {

            # Get OS file name
            $OperatingSystemFile = $this.OperatingSystemPath
        }

        # Get existing OS file name
        If ($this.WIMFileName)
        {
            $Directory = $this.Name.Replace(" x64","")
            $Directory = $Directory.Replace(" x32","")

            $OperatingSystemFiles = (Get-ChildItem -Path "$($this.PSDriveName):\Operating Systems\$($this.Path.Split("\")[-1])")
            ForEach ($OSFile in $OperatingSystemFiles)
            {
                If ($OSFile.Name -like "*$($this.WIMFileName)*")
                {
                    $OperatingSystemFile = "$($this.PSDriveName):\Operating Systems\$($this.Path.Split("\")[-1])\$($OSFile.Name)"
                }
            }
        }

        If ($OperatingSystemFile)
        {

            # Create path for task sequence
            Invoke-CreatePath -Path "$($this.PSDriveName):\Task Sequences\$($this.Path.Split("\")[-1])" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            # Import task sequence
            Import-MDTTaskSequence -path $this.Path -Name $this.Name -Template "Client.xml" -Comments "" -ID $this.ID -Version "1.0" -OperatingSystemPath $OperatingSystemFile -FullName "Windows User" -OrgName "Addlevel" -HomePage "about:blank" -Verbose
        }
    }
}
[DscResource()]
class cMDT_TS_Step_SetVariable
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$TaskSequenceParentGroupName

    [DscProperty(Key)]
    [string]$TaskSequenceVariableName

    [DscProperty(Key)]
    [string]$TaskSequenceVariableValue
    
    [DscProperty(Key)]
    [string]$TaskSequenceStepName

    [DscProperty()]
    [string]$TaskSequenceStepDescription

    [DscProperty()]
    [bool]$Disable

    [DscProperty()]
    [bool]$ContinueOnError

    [DscProperty()]
    [string]$SuccessCodeList

    [DscProperty(Key)]
    [string]$TaskSequenceId

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty(Mandatory)]
    [string]$InsertAfterStep

    [void] Set()
    {    
        [xml]$xml = $this.ReadTaskSequenceXML()
        
        $present         = $this.TaskSequenceStepExists()
        $stepNeedsUpdate = $this.TaskSequenceStepNeedsUpdate()
        
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false)
        {
            if ($stepNeedsUpdate)
            {
                $this.UpdateTaskSequenceStep($xml)
            }
            else
            {
                $this.CreateTaskSequenceStep($xml)
            }
        }
        elseif ($this.Ensure -eq [ensure]::Absent -and $present -eq $true)
        {
            $this.RemoveTaskSequenceStep($xml)
        }
        
    }

    [bool] Test()
    {
        
        $present = $this.TaskSequenceStepExists()

        if ($this.Ensure -eq [ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDT_TS_Step_SetVariable] Get()
    {
        return $this
    }

    [bool] TaskSequenceStepExists()
    {
        [xml]$xml = $this.ReadTaskSequenceXML()
        
        #Select parent group by name
        $parentGroup = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        #Select parent node by name
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

        #Next sibling should be the same name as the task sequence step name if it exists.
        if ($insertAfterNode.NextSibling.name -eq $($this.TaskSequenceStepName))
        {
            if ($this.TaskSequenceStepNeedsUpdate())
            {
                return $false
            }   
            return $true
        }
        return $false
    }

    [bool] TaskSequenceStepNeedsUpdate()
    {        
        [xml]$xml        = $this.ReadTaskSequenceXML()
        $parentGroup     = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")
        
        if ($insertAfterNode.NextSibling.name -ne $($this.TaskSequenceStepName))
        {
            return $false
        }

        $node      = $insertAfterNode.NextSibling
        $varName   = $node.defaultVarList.SelectSingleNode("variable[@name='VariableName']").InnerText
        $varValue  = $node.defaultVarList.SelectSingleNode("variable[@name='VariableValue']").InnerText

        if ($varName              -ne $this.TaskSequenceVariableName)    {return $true}
        if ($varValue             -ne $this.TaskSequenceVariableValue)   {return $true}
        if ($node.description     -ne $this.TaskSequenceStepDescription) {return $true}
        if ($node.disable         -ne $this.Disable)                     {return $true}
        if ($node.continueOnError -ne $this.ContinueOnError)             {return $true}
        if ($node.successCodeList -ne $this.SuccessCodeList)             {return $true}
            
        return $false        
    }

    [void] CreateTaskSequenceStep($xml)
    {
        $parentGroup = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")
    
        $stepNode = $xml.CreateElement("step")
        $stepNode.SetAttribute("type","SMS_TaskSequence_SetVariableAction")
        $stepNode.SetAttribute("name","$($this.TaskSequenceStepName)")
        $stepNode.SetAttribute("description","$($this.TaskSequenceStepDescription)")
        $stepNode.SetAttribute("disable","$($this.Disable.ToString().ToLower())")
        $stepNode.SetAttribute("continueOnError","$($this.ContinueOnError.ToString().ToLower())")
        $stepNode.SetAttribute("successCodeList","$($this.SuccessCodeList)")
            $defaultVarListNode = $xml.CreateElement("defaultVarList")
                $variableNode1 = $xml.CreateElement("variable")
                $variableNode1.SetAttribute("name","VariableName")
                $variableNode1.SetAttribute("property","VariableName")
                $variableNode1.InnerText = "$($this.TaskSequenceVariableName)"
                $defaultVarListNode.AppendChild($variableNode1) > $null

                $variableNode2 = $xml.CreateElement("variable")
                $variableNode2.SetAttribute("name","VariableValue")
                $variableNode2.SetAttribute("property","VariableValue")
                $variableNode2.InnerText = "$($this.TaskSequenceVariableValue)"
                $defaultVarListNode.AppendChild($variableNode2) > $null

            $stepNode.AppendChild($defaultVarListNode) > $null
            $actionNode = $xml.CreateElement("action")
            $actionNode.InnerText = "cscript.exe `"%SCRIPTROOT%\ZTISetVariable.wsf`""
        $stepNode.AppendChild($actionNode) > $null
    
        $parentGroup.InsertAfter($stepNode,$insertAfterNode)
        $this.SaveTaskSequenceXML($xml)
    }

    [void] UpdateTaskSequenceStep($xml)
    {
        $parentGroup     = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")
        $node            = $insertAfterNode.NextSibling

        $node.SetAttribute("name","$($this.TaskSequenceStepName)")
        $node.SetAttribute("description","$($this.TaskSequenceStepDescription)")
        $node.SetAttribute("disable","$($this.Disable.ToString().ToLower())")
        $node.SetAttribute("continueOnError","$($this.ContinueOnError.ToString().ToLower())")
        $node.SetAttribute("successCodeList","$($this.SuccessCodeList)")

        $node.defaultVarList.SelectSingleNode("variable[@name='VariableName']").InnerText  = $this.TaskSequenceVariableName
        $node.defaultVarList.SelectSingleNode("variable[@name='VariableValue']").InnerText = $this.TaskSequenceVariableValue
        
        $this.SaveTaskSequenceXML($xml)
    }

    [void] RemoveTaskSequenceStep($xml)
    {
        $parentGroup = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        #Select parent node by name
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

        #Next sibling should be the same name as the task sequence step name if it exists.
        if ($insertAfterNode.NextSibling.name -eq $($this.TaskSequenceStepName))
        {
            $node = $insertAfterNode.NextSibling
            $node.ParentNode.RemoveChild($node) > $null
            $this.SaveTaskSequenceXML($xml)
        }
    }
    
    [xml] ReadTaskSequenceXML()
    {
        return [xml](Get-Content -Path "$($this.PSDrivePath)\Control\$($this.TaskSequenceId)\ts.xml")
    }
    [void] SaveTaskSequenceXML($xml)
    {
        $xml.Save("$($this.PSDrivePath)\Control\$($this.TaskSequenceId)\ts.xml")
    }
}[DscResource()]
class cMDTUpdateBootImage
{
    [DscProperty(Key)]
    [string]$Version

    [DscProperty(Key)]
    [string]$PSDeploymentShare

    [DscProperty(Mandatory)]
    [bool]$Force

    [DscProperty(Mandatory)]
    [bool]$Compress

    [DscProperty(Mandatory)]
    [string]$DeploymentSharePath

    [DscProperty()]
    [string]$ExtraDirectory

    [DscProperty()]
    [string]$BackgroundFile

    [DscProperty()]
    [string]$LiteTouchWIMDescription

    [DscProperty()]
    [string]$FeaturePacks
      
    [void] Set()
    {
        $this.UpdateBootImage()
    }

    [bool] Test()
    {
        Return ($this.VerifyVersion())
    }

    [cMDTUpdateBootImage] Get()
    {
        return $this
    }

    [bool] VerifyVersion()
    {
        [bool]$match = $false

        if ((Get-Content -Path "$($this.DeploymentSharePath)\Boot\CurrentBootImage.version" -ErrorAction Ignore) -eq $this.Version)
        {
            $match = $true
        }
        
        return $match
    }

    [void] UpdateBootImage()
    {

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $this.PSDeploymentShare -PSProvider "MDTProvider" -Root $this.DeploymentSharePath -Verbose:$false

        If ([string]::IsNullOrEmpty($($this.ExtraDirectory)))
        {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.ExtraDirectory -Value ""
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.ExtraDirectory -Value ""
        }
        ElseIf (Invoke-TestPath -Path "$($this.DeploymentSharePath)\$($this.ExtraDirectory)")
        {

            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.ExtraDirectory -Value "$($this.DeploymentSharePath)\$($this.ExtraDirectory)"                        
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.ExtraDirectory -Value "$($this.DeploymentSharePath)\$($this.ExtraDirectory)"                       
        }

        If ([string]::IsNullOrEmpty($($this.BackgroundFile)))
        {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.BackgroundFile -Value ""
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.BackgroundFile -Value ""
        }

        ElseIf(Invoke-TestPath -Path "$($this.DeploymentSharePath)\$($this.BackgroundFile)")
        {
             Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.BackgroundFile -Value "$($this.DeploymentSharePath)\$($this.BackgroundFile)"
             Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.BackgroundFile -Value "$($this.DeploymentSharePath)\$($this.BackgroundFile)"
        }

        If($this.LiteTouchWIMDescription) { Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.LiteTouchWIMDescription -Value "$($this.LiteTouchWIMDescription) x64 $($this.Version)" }
        Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.GenerateLiteTouchISO -Value $false

        If($this.LiteTouchWIMDescription) { Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.LiteTouchWIMDescription -Value "$($this.LiteTouchWIMDescription) x86 $($this.Version)" }
        Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.GenerateLiteTouchISO -Value $false
        

        If ([string]::IsNullOrEmpty($($this.FeaturePacks)))
        {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.FeaturePacks -Value ""
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.FeaturePacks -Value ""
        }
        Else
        {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.FeaturePacks -Value $($this.FeaturePacks)
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.FeaturePacks -Value $($this.FeaturePacks)
        }

        #The Update-MDTDeploymentShare command crashes WMI when run from inside DSC. This section is a work around.
        $aPSDeploymentShare = $this.PSDeploymentShare
        $aDeploymentSharePath = $this.DeploymentSharePath
        $aForce = $this.Force
        $aCompress = $this.Compress
        $jobArgs = @($aPSDeploymentShare,$aDeploymentSharePath,$aForce,$aCompress)

        $job = Start-Job -Name UpdateMDTDeploymentShare -Scriptblock {
            Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1" -ErrorAction Stop -Verbose:$false
            New-PSDrive -Name $args[0] -PSProvider "MDTProvider" -Root $args[1] -Verbose:$false
            Update-MDTDeploymentShare -Path "$($args[0]):" -Force:$args[2] -Compress:$args[3]
        } -ArgumentList $jobArgs

        $job | Wait-Job -Timeout 1800 
        $timedOutJobs = Get-Job -Name UpdateMDTDeploymentShare | Where-Object {$_.State -eq 'Running'} | Stop-Job -PassThru

        If ($timedOutJobs)
        {
            Write-Error "Update-MDTDeploymentShare job exceeded timeout limit of 900 seconds and was aborted"
        }
        Else
        {
            Set-Content -Path "$($this.DeploymentSharePath)\Boot\CurrentBootImage.version" -Value "$($this.Version)"
        }
    }
    
    
}
[DscResource()]
class cWDSBootImage
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Version

    [DscProperty(Key)]
    [string]$ImageName

    [void] Set()
    {

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $this.AddBootImage()
        }
        else
        {
            $this.RemoveBootImage()
        }
    }

    [bool] Test()
    {
        Return ($this.VerifyVersion())
    }

    [cWDSBootImage] Get()
    {
        return $this
    }

    [bool] VerifyVersion()
    {
        [bool]$match = $false

        $foldername = $this.Path.Replace("\$($this.Path.Split("\")[-1])","")

        if ((Get-Content -Path "$($foldername)\WSDBootImage.version" -ErrorAction Ignore) -eq $this.Version)
        {
            $match = $true
        }
        
        return $match
    }

    [bool] DoesBootImageExist()
    {
       return ((Get-WdsBootImage -ImageName $this.ImageName) -ne $null)
    }

    [void] AddBootImage()
    {
        If ($this.DoesBootImageExist()) { $this.RemoveBootImage() }

        Import-WdsBootImage -Path $this.Path -NewImageName $this.ImageName –SkipVerify | Out-Null

        $foldername = $this.Path.Replace("\$($this.Path.Split("\")[-1])","")

        if (-not (Get-Content -Path "$($foldername)\WSDBootImage.version" -ErrorAction Ignore))
        {
            New-ReferenceFile -Path "$($foldername)\WSDBootImage.version"
        }

        Set-Content -Path "$($foldername)\WSDBootImage.version" -Value "$($this.Version)"
    }
    
    [void] RemoveBootImage()
    {
        Get-WdsBootImage -ImageName $this.ImageName | Remove-WdsBootImage
    }
    
}
[DscResource()]
class cWDSConfiguration
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$RemoteInstallPath


    [void] Set()
    {

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $this.InitializeServer()
        }
        else
        {
            $this.UninitializeServer()
        }
    }

    [bool] Test()
    {
        $present = $this.DoesRemoteInstallFolderExist()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [bool] IsPartOfDomain()
    {
        return (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    }

    [cWDSConfiguration] Get()
    {
        return $this
    }

    [bool] DoesRemoteInstallFolderExist()
    {
        return (Test-Path $this.RemoteInstallPath -ErrorAction Ignore)
    }

    [void] InitializeServer()
    {
        if ($this.IsPartOfDomain())
        {
            & WDSUTIL /Initialize-Server /RemInst:"$($this.RemoteInstallPath)" /Authorize
        }
        else
        {
            & WDSUTIL /Initialize-Server /RemInst:"$($this.RemoteInstallPath)" /Standalone
        }        
        & WDSUTIL /Set-Server /AnswerClients:All

    }
    
    [void] UninitializeServer()
    {
       & WDSUTIL /Uninitialize-Server
    }
    
}
Function Compare-Version
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Source,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Target
    )

    [bool]$match = $false

    if ((Get-Content -Path $Source) -eq $Target)
    {
        $match = $true
    }

    return $match
}
Function Get-FileNameFromPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Separator
    )

    [string]$fileName = $Path.Split($Separator)[-1]

    return $fileName

}
Function Get-FileTypeFromPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Separator
    )

    [string]$fileType = ($Path.Split($Separator)[-1]).Split(".")[-1]

    return $fileType

}
Function Get-FolderNameFromPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Separator
    )

    [string]$folderName = $Path.Replace("\$($Path.Split($Separator)[-1])","")

    return $folderName

}
Function Get-Separator
{
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path
    )

    [string]$separator = ""
    If ($Path -like "*/*")
    { $separator = "/" }
    Else
    { $separator = "\" }

    return $separator

}
Function Get-Separator
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path
    )

    [string]$separator = ""
    If ($Path -like "*/*")
    { $separator = "/" }
    Else
    { $separator = "\" }

    return $separator

}
Function Import-MicrosoftDeploymentToolkitModule
{
    If (-Not(Get-Module MicrosoftDeploymentToolkit))
    {
        Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1" -ErrorAction Stop -Global -Verbose:$False
    }
}
Function Invoke-CreatePath
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter()]
        [string]$PSDriveName,

        [Parameter()]
        [string]$PSDrivePath
    )

    [bool]$present = $false

    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$false

        $Script:Directory = $($($Path.Split("\"))[0])
        For ($i=1; $i -le $($Path.Split("\").Count-1); $i++) {
            $Script:Directory += "\$($($Path.Split("\"))[$i])"
            If(-not(Invoke-TestPath -Path $Script:Directory -PSDriveName $PSDriveName -PSDrivePath $PSDrivePath -Verbose))
            {
                Try
                {
                    New-Item -ItemType Directory -Path $Script:Directory  -Verbose
                    If ($this.Debug) { Invoke-Logger -Message "Successfully created: $Directory" -Severity D -Category "DIRECTORY" -Type "CREATE" }
                    $present = $true

                }
                Catch
                {
                    If ($this.Debug) { Invoke-Logger -Severity E -Category "DIRECTORY" -Type "CREATE" -Error $Error[0] }
                }
            }
        }
             
    }
    else
    {

        $Script:Directory = $($($Path.Split("\"))[0])
        For ($i=1; $i -le $($Path.Split("\").Count-1); $i++) {
            $Script:Directory += "\$($($Path.Split("\"))[$i])"
            If(-not(Invoke-TestPath -Path $Script:Directory -Verbose))
            {
                Try
                {
                    New-Item -ItemType Directory -Path $Script:Directory -Verbose
                    If ($this.Debug) { Invoke-Logger -Message "Successfully created: $Directory" -Severity D -Category "DIRECTORY" -Type "CREATE" }
                    $present = $true
                }
                Catch
                {
                    If ($this.Debug) { Invoke-Logger -Severity E -Category "DIRECTORY" -Type "CREATE" -Error $Error[0] }
                }
            }
        }
    }

    return $present
}
Function Invoke-ExpandArchive
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Source,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Target
    )

    [bool]$Verbosity
    If($PSBoundParameters.Verbose)
    { $Verbosity = $True }
    Else
    { $Verbosity = $False }

    Write-Verbose "Expanding archive $($Source) to $($Target)"
    Expand-Archive $Source -DestinationPath $Target -Force -Verbose:$Verbosity
}
Function Invoke-Logger
{
    param(
        [String]$Severity,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [String]$Category,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [String]$Type,

        $Message,

        $Error
    )

    Switch ($Severity) 
    { 
        "I"     { $Severity = "INFO" }
        "D"     { $Severity = "DEBUG" }
        "W"     { $Severity = "WARNING" }
        "E"     { $Severity = "ERROR"}
        default { $Severity = "INFO" }
    }

    $date = [datetime]::UtcNow
    
    For ($x=$Severity.Length; $x -le 6; $x++)  { $Severity = $Severity+" " }
    For ($x=$Category.Length; $x -le 7; $x++) { $Category = $Category+" " }
    For ($x=$Type.Length;     $x -le 7; $x++) { $Type     = $Type+" " }

    If ($Error)
    {
        ForEach ($Line in $Message)
        {
            Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Line)]"
        }
        If ($Error.Exception.Message) { Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Error.Exception.Message)]" }
        If ($Error.Exception.Innerexception) { Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Error.Exception.Innerexception)]" }
        If ($Error.InvocationInfo.PositionMessage) {
            ForEach ($Line in $Error.InvocationInfo.PositionMessage.Split("`n"))
            {
                Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Line)]"
            }
        }
    }
    Else
    {
        If ($Message)
        {
            If (($Message.GetType()).Name -eq "Hashtable")
            {
                Get-RecursiveProperties -Value $Message
            }
            Else
            {
                ForEach ($Line in $Message)
                {
                    Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Line)]"
                }
            }
        }
    }

}

#<![LOG[Report state message 0x40000950 to MP]LOG]!><time="01:38:47.034-120" date="07-16-2016" component="SMS_Distribution_Point_Monitoring" context="" type="1" thread="12172" file="smsdpmon.cpp:889">
#<![LOG[Begin validation of Certificate [Thumbprint 5F1966C815ADC9B25E8D9979917E26B5396D9154] issued to 'winPE.dec.addlevel.net']LOG]!><time="19:25:40.755-120" date="05-27-2016" component="SMSPXE" context="" type="1" thread="7484" file="ccmcert.cpp:1715"> 

Function Invoke-RemovePath
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter()]
        [string]$PSDriveName,

        [Parameter()]
        [string]$PSDrivePath,

        [Parameter()]
        [int32]$Levels,

        [Parameter()]
        [switch]$Recurse
    )

    [bool]$Verbosity
    If($PSBoundParameters.Verbose)
    { $Verbosity = $True }
    Else
    { $Verbosity = $False }

    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$False        Try
        {
            Remove-Item -Path $Path -Force -Verbose:$Verbosity
            If ($this.Debug) { Invoke-Logger -Message "Successfully removed: $Path" -Severity D -Category "DIRECTORY" -Type "REMOVE" }
        }
        Catch
        {
            If ($this.Debug) { Invoke-Logger -Severity E -Category "DIRECTORY" -Type "CREATE" -Error $Error[0] }
        }
        If ($Recurse)
        {
            $Script:Dir = $Path
            For ($i=$($Path.Split("\").Count-1); $i -ge $Levels; $i--) {
                $Script:Dir = $Script:Dir.Replace("\$($($Path.Split("\"))[$i])","")
                If(-not(Invoke-TestPath -Path "$Dir\*" -PSDriveName $PSDriveName -PSDrivePath $PSDrivePath -Verbose))
                {
                    Try
                    {
                        Remove-Item -Path $Dir -Force -Verbose:$Verbosity
                        If ($this.Debug) { Invoke-Logger -Message "Successfully removed: $Dir" -Severity D -Category "DIRECTORY" -Type "REMOVE" }
                    }
                    Catch
                    {
                        If ($this.Debug) { Invoke-Logger -Severity E -Category "DIRECTORY" -Type "CREATE" -Error $Error[0] }
                    }

                }
            }
        }

    }
    else
    {

        Try
        {
            Remove-Item -Path $Path -Force -Verbose:$Verbosity
            If ($this.Debug) { Invoke-Logger -Message "Successfully removed: $Path" -Severity D -Category "DIRECTORY" -Type "REMOVE" }
        }
        Catch
        {
            If ($this.Debug) { Invoke-Logger -Severity E -Category "DIRECTORY" -Type "CREATE" -Error $Error[0] }
        }

        If ($Recurse)
        {
            $Script:Dir = $Path
            For ($i=$($Path.Split("\").Count-1); $i -ge 4; $i--) {
                $Script:Dir = $Script:Dir.Replace("\$($($Path.Split("\"))[$i])","")
                If(-not(Invoke-TestPath -Path "$Dir\*" -Verbose))
                {
                    Try
                    {
                        Remove-Item -Path $Dir -Force -Verbose:$Verbosity
                        If ($this.Debug) { Invoke-Logger -Message "Successfully removed: $Dir" -Severity D -Category "DIRECTORY" -Type "REMOVE" }
                    }
                    Catch
                    {
                        Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
                    }
                }
            }
        }

    }
}
Function Invoke-TestPath
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter()]
        [string]$PSDriveName,

        [Parameter()]
        [string]$PSDrivePath
    )

    [bool]$present = $false

    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule

        if (New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$false | `            Test-Path -Path $Path -ErrorAction Ignore)
        {
            $present = $true
        }

    }
    else
    {

        if (Test-Path -Path $Path -ErrorAction Ignore)
        {
            $present = $true
        }

    }

    return $present
}
Function Invoke-WebDownload
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Source,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Target
    )

    [bool]$Verbosity
    If($PSBoundParameters.Verbose)
    { $Verbosity = $True }
    Else
    { $Verbosity = $False }

    If ($Source -like "*/*")
    {
        If (Get-Service BITS | Where-Object {$_.status -eq "running"})
        {

            If ($Verbosity) { Write-Verbose "Downloading file $($Source) via Background Intelligent Transfer Service" }
            Import-Module BitsTransfer -Verbose:$false
            Start-BitsTransfer -Source $Source -Destination $Target -Verbose:$Verbosity
            Remove-Module BitsTransfer -Verbose:$false
        }
        else
        {

            If ($Verbosity) { Write-Verbose "Downloading file $($Source) via System.Net.WebClient" }
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($Source, $Target)
        }
    }
    Else
    {
        If (Get-Service BITS | Where-Object {$_.status -eq "running"})
        {
            If ($Verbosity) { Write-Verbose "Downloading file $($Source) via Background Intelligent Transfer Service" }
            Import-Module BitsTransfer -Verbose:$false
            Start-BitsTransfer -Source $Source -Destination $Target -Verbose:$Verbosity
        }
        Else
        {
            Copy-Item $Source -Destination $Target -Force -Verbose:$Verbosity
        }
    }
}
Function New-ReferenceFile
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,
        [Parameter()]
        [string]$PSDriveName,
        [Parameter()]
        [string]$PSDrivePath
    )
    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule        New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$false | `        New-Item -Type File -Path $Path -Force -Verbose:$False     
    }
    else
    {

        New-Item -Type File -Path $Path -Force -Verbose:$False  
    }
}
Function Write-Log
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        $Message
    )
    [String]$LogFile = "$($PSScriptRoot)\$(Get-Date -Format "yyyy-MM-dd")_cMDT.log"
    Out-File -FilePath $LogFile -InputObject $Message -Encoding utf8 -Append -NoClobber
    #Write-Verbose $Message
}
