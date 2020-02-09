function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("EnableCollection","EnableRules")]
        [System.String]
        $Action
    )

    #Check if GPO policy has been set
    switch($Action)
    {
        "EnableCollection"
        {
            $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service"
        }
        "EnableRules"
        {
            $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client"
        }
    }
    $RegValueName = "AllowCredSSP"

    if (Test-RegistryValue -Path $RegKey -Name $RegValueName)
    {
        Write-Verbose -Message "CredSSP is configured via Group Policies"
    }
    else
    {
        # Check regular values
        switch($Action)
        {
            "EnableCollection"
            {
                $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Service"
            }
            "EnableRules"
            {
                $RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client"
            }
        }
        $RegValueName = "auth_credssp"
    }

    if(Test-RegistryValue -Path $RegKey -Name $RegValueName)
    {
        $Setting = (Get-ItemProperty -Path $RegKey -Name $RegValueName).$RegValueName
    }
    else
    {
        $Setting = 0
    }

    switch($Action)
    {
        "EnableCollection"
        {
            switch($Setting)
            {
                1
                {
                    $returnValue = @{
                        Ensure = "Present";
                        Role = "Server"
                    }
                }
                0
                {
                    $returnValue = @{
                        Ensure = "Absent";
                        Role = "Server"
                    }
                }
            }
        }
        "EnableRules"
        {
            switch($Setting)
            {
                1
                {   
                    $key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"

                    $DelegateComputers = @()


                    Get-Item -Path $key -ErrorAction SilentlyContinue |
                        Select-Object -ExpandProperty Property | 
                        ForEach-Object {
                            $DelegateComputer = ((Get-ItemProperty -Path $key -Name $_).$_).Split("/")[1]
                            $DelegateComputers += $DelegateComputer
                        }
                    $DelegateComputers = $DelegateComputers | Sort-Object -Unique

                    $returnValue = @{
                        Ensure = "Present";
                        Role = "Client";
                        DelegateComputers = @($DelegateComputers)
                    }
                }
                0
                {
                    $returnValue = @{
                        Ensure = "Absent";
                        Role = "Client"
                    }
                }
            }
        }
    }

    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateSet("EnableCollection","EnableRules")]
        [System.String]
        $Action,

        [System.Boolean]
        $SuppressReboot = $false        
    )


    switch($Action)
    {
        "EnableCollection"
        {
            switch($Ensure)
            {
                "Present"
                {
					$cfgBrowserDll = gci ${env:ProgramFiles(x86)} -Filter Quest.InTrust.ConfigurationBrowser.dll -Recurse -ErrorAction Ignore

					[Reflection.Assembly]::LoadFrom($cfgBrowserDll.FullName) | Out-Null

					$cfgBrowser = New-Object Quest.InTrust.ConfigurationBrowser.InTrustConfigurationBrowser($false)

					$cfgBrowser.ConnectLocal()
					$currentName = "AllDomainAllLogs"
					$collection = $cfgBrowser.Configuration.Collections.AddCollection([Guid]::NewGuid(),$currentName)
					$collection.IsEnabled = $true
					$collection.RepositoryId = $cfgBrowser.Configuration.DataStorages.GetDefaultRepository().Guid
					$rtcSite = $cfgBrowser.Configuration.Sites.AddRtcSite($currentName)
					$collection.AddSiteReference($rtcSite.Guid)
					$rtcSite.AddDomain([Guid]::NewGuid(),$env:USERDNSDOMAIN,$false,$false)
					$rtcSite.OwnerServerId = $cfgBrowser.GetServer().Guid
					$rtcSite.Update()
					$cfgBrowser.Configuration.DataSources.ListDataSources() | ?{$_.ProviderID -eq 'a9e5c7a2-5c01-41b7-9d36-e562dfddefa9'} | %{$collection.AddDataSourceReference($_.Guid)}
					$collection.Update()
					$collection.Dispose();$rtcSite.Dispose();
                }
                "Absent"
                {
					$cfgBrowserDll = gci ${env:ProgramFiles(x86)} -Filter Quest.InTrust.ConfigurationBrowser.dll -Recurse -ErrorAction Ignore

					[Reflection.Assembly]::LoadFrom($cfgBrowserDll.FullName) | Out-Null

					$cfgBrowser = New-Object Quest.InTrust.ConfigurationBrowser.InTrustConfigurationBrowser($false)

					$cfgBrowser.ConnectLocal()
					$currentName = "AllDomainAllLogs"
					$cfgBrowser.Configuration.Collections.ListCollections() | ?{$_.Name -eq $currentName} | %{$cfgBrowser.Configuration.Collections.RemoveCollection($_.Guid)}
                }
            }
        }
        "EnableRules"
        {
            switch($Ensure)
            {
                "Present"
                {
                    if($DelegateComputers)
                    {
                        $key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials"

                        if (!(test-path $key))
                        {
                            New-Item $key -Force | out-null
                        }

                        $CurrentDelegateComputers = @()

                        Get-Item -Path $key |
                            Select-Object -ExpandProperty Property | 
                            ForEach-Object {
                                $CurrentDelegateComputer = ((Get-ItemProperty -Path $key -Name $_).$_).Split("/")[1]
                                $CurrentDelegateComputers += $CurrentDelegateComputer
                            }
                        $CurrentDelegateComputers = $CurrentDelegateComputers | Sort-Object -Unique

                        foreach($DelegateComputer in $DelegateComputers)
                        {
                            if(($CurrentDelegateComputers -eq $NULL) -or (!$CurrentDelegateComputers.Contains($DelegateComputer)))
                            {
                                Enable-WSManCredSSP -Role Client -DelegateComputer $DelegateComputer -Force | Out-Null
                                if ($SuppressReboot -eq $false)
                                {
                                   $global:DSCMachineStatus = 1
                                }
                            }
                        }
                    }
                    else
                    {
                        Throw "DelegateComputers is required!"
                    }
                }
                "Absent"
                {
                    Disable-WSManCredSSP -Role Client | Out-Null
                }
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [ValidateSet("EnableCollection","EnableRules")]
        [System.String]
        $Action,

        [System.String[]]
        $DelegateComputers,

        [System.Boolean]
        $SuppressReboot = $false    
    )

    if ($Action -eq "EnableCollection" -and $PSBoundParameters.ContainsKey("DelegateComputers")) 
    {
        Write-Verbose -Message ("Cannot use the Role=Server parameter together with " + `
                                "the DelegateComputers parameter")
    }

    $CredSSP = Get-TargetResource -Role $Action

    switch($Action)
    {
        "EnableCollection"
        {
            return ($CredSSP.Ensure -eq $Ensure)
        }
        "EnableRules"
        {
            switch($Ensure)
            {
                "Present"
                {
                    $CorrectDelegateComputers = $true
                    if($DelegateComputers)
                    {
                        foreach($DelegateComputer in $DelegateComputers)
                        {
                            if(!($CredSSP.DelegateComputers | Where-Object {$_ -eq $DelegateComputer}))
                            {
                                $CorrectDelegateComputers = $false
                            }
                        }
                    }
                    $result = (($CredSSP.Ensure -eq $Ensure) -and $CorrectDelegateComputers)
                }
                "Absent"
                {
                    $result = ($CredSSP.Ensure -eq $Ensure)
                }
            }
        }
    }

    return $result
}


Export-ModuleMember -Function *-TargetResource


function Test-RegistryValue
{
    param (
        [Parameter(Mandatory = $true)]
        [String]$Path
        ,
        [Parameter(Mandatory = $true)]
        [String]$Name
    )
    
    if ($null -eq $Path)
    {
        return $false
    }

    $itemProperties = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
    return ($null -ne $itemProperties -and $null -ne $itemProperties.$Name)
}
