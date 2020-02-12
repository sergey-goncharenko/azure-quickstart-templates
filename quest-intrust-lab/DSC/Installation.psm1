. "$PSScriptRoot\CommonUtilities.ps1"
. "$PSScriptRoot\InstallationUtilities.ps1"


#if ([Environment]::Is64BitProcess) { throw "Use x86 powershell" }

function Install-VCRedist
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageRootPath ,
        
        [string]
        $RelativePath = "Redist"
    )

    $packageFileInfo =  Get-InTrustPackageInfo  -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "vcredist_x86.exe" -LiteralName
    if($packageFileInfo -ne $null)
    {
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo  } 
    }
    
    return -1
}


function Install-SQLNativeClient
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "Redist"
    )
    
    $packageFileInfo =  Get-InTrustPackageInfo  -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "sqlncli.msi" -LiteralName
    if($packageFileInfo -ne $null)
    {
		$installArguments = "IACCEPTSQLNCLILICENSETERMS=YES"
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments  }
    }
    
    return -1    
}


function Install-InTrustServer
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Server",
		
		[string]
		$username ="",
		
		[System.Management.Automation.PSCredential] 
		$Credential
    )
            
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "ADCSRV"
    if($packageFileInfo -ne $null)
    {
        $installArguments = Get-SeverInstallArguments
        
        return Retry-Command {
            if($username -eq ""){$result = Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments }
			else{$result = Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments -username $username -Credential $Credential}
            if(($result -eq 0) -or ($result -eq 3010))
            {
                write-Host "Waiting for InTrust service started after install"
                if(-not (Start-LocalInTrustServices))
                {
                    Write-Warning "InTrust service not started after install"
                }
                #Sleep -second 30
            }
            return $result
        }
    }
    
    return -1
}


function Install-InTrustManager
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\InTrust Manager"
    )
            
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath  -RelativePath $RelativePath -PackageName "IT_ADMIN"
    if ($packageFileInfo -ne $null)
    {
        $installArguments = Get-TargetPathSetting
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments   }
    } 

    return -1
}


function Install-InTrustDeploymentManager
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\InTrust Manager"
    )
    
    $packageFileInfo = Get-InTrustPackageInfo  -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "RTC_UI"
    if ($packageFileInfo -ne $null)
    {
        $installArguments = Get-TargetPathSetting
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments   }
    } 
    
    return -1
}


function Install-InTrustRV
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]        
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Repository Viewer"
    )
    
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "IT_RV" 
    if ($packageFileInfo -ne $null)
    {
        $installArguments = Get-TargetPathSetting -InstallPathParamName "PF_IT8RV" -InstallPathRelativeValue "Repository Viewer\" 
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments   }
    } 
    
    return -1
}


function Install-InTrustSDK
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Server"
    )
    
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "INTRUST_SDK"
    if ($packageFileInfo -ne $null)
    {
       return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo  }
    } 
    
    return -1
}

function Install-InTrustIndexingTool
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Server"
    )
    
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "INDEXING_TOOL"
	if ($packageFileInfo -ne $null)
    {
		$installArguments = Get-TargetPathSetting
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments}
    } 
    
    return -1
}


function Install-InTrustResourceKit
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Server"
    )
        
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "ADC_SERVER_RESOURCE_KIT"
    if ($packageFileInfo -ne $null)
    {
       return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo  }
    } 
    
    return -1
}


function Install-InTrustMonitoringConsole
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Monitoring Console"
    )
    
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "IT_WEB"
    if ($packageFileInfo -ne $null)
    {
        $installArguments = Get-MonitoringConsoleInstallArguments
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments   }
    } 
    
    return -1
}


function Install-InTrustKnowledgePortal
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Knowledge Portal\"
    )
            
    $packageFileInfo = Get-InTrustPackageInfo  -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName "QKnowledgePortal"
    if ($packageFileInfo -ne $null)
    {
        $installArguments = Get-KnowledgePortalInstallArguments
        return Retry-Command { Start-InstallationProgram -ArgumentList $installArguments -PackageFileInfo $packageFileInfo   }
    } 
    
    return -1
}


function Install-InTrustKnowledgePacks
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Server",
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WildcardPackName
    )
    
    $packageFiles = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName $WildcardPackName
    if($packageFiles -ne $null)
    {
        foreach($packageInfo in $packageFiles)
        {
            $result = Retry-Command { Start-InstallationProgram -PackageFileInfo $packageInfo }
            if(($result -ne 0) -and ($result -ne 3010))
            {
                return -1
            }
        }
        
        return 0
    }    
        
    return -1
}


function Install-InTrustReportPacks
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]           
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Report Packs\",
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $WildcardPackName = "*"
    )
        
    $packageFiles = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName $WildcardPackName
    if($packageFiles -ne $null)
    {
        foreach($packageInfo in $packageFiles)
        {    
            $result = Retry-Command { Start-InstallationProgram -PackageFileInfo $packageInfo }
            if(($result -ne 0) -and ($result -ne 3010))
            {
                return -1
            }
        }
        
        return 0
    }    
    
    return -1
}


function Install-InTrustDefaultKnowledgePacks
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]   
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Server"
    )
    
    Install-InTrustKnowledgePacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName "KP" 
    Install-InTrustKnowledgePacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName "KM" 
    Install-InTrustKnowledgePacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName "KnowledgePack"  
}


function Install-InTrustDefaultReportPacks
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]       
        [String]
        $PackageRootPath,

        [string]
        $RelativePath = "InTrust\Report Packs\"
    )
    
    return Install-InTrustReportPacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName "*" 
}


function Install-InTrustAdditionalReportPack
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageRootPath,
        
        [String]
        $RelativePath = "Additional Knowledge Packs",
        
        [string]
        $WildcardPackName = "IT_ActiveRoleServer"
    )

    return Install-InTrustReportPacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName $WildcardPackName 
}


function Install-InTrustAdditionalKnowledgePack
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageRootPath,

        [String]
        $RelativePath = "Additional Knowledge Packs",
        
        [string]
        $WildcardPackName = "ARS_KP"
    )

    return Install-InTrustKnowledgePacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName $WildcardPackName 
}


function Install-InTrustITACS4SCOMPackage
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageRootPath,
                
        [String]
        $RelativePath = "Add-ins\ACS Add-ins",
        
        [string]
        $WildcardName = "IT_ACS4SCOM"
    )
    
    return Install-InTrustReportPacks -PackageRootPath $PackageRootPath -RelativePath $RelativePath -WildcardPackName $WildcardName 
}


function Install-InTrustITC4SCOMPackage
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageRootPath,

        [String]
        $RelativePath = "Add-ins\InTrust Connector for OpsManager",
        
        [string]
        $WildcardName = "ITC4SCOM"
    )
    
    $packageFileInfo =  Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath $RelativePath -PackageName $WildcardName 
    if($packageFileInfo -ne $null)
    {
        $installArguments = Get-TargetPathSetting -InstallPathParamName "PF_IT_SCOM" -InstallPathRelativeValue "\InTrust Connector for Microsoft System Center Operations Manager\"
        return Retry-Command { Start-InstallationProgram -ArgumentList $installArguments -PackageFileInfo $packageFileInfo   }
    }
    
    return -1
}


function Install-InTrustWindowsAgent
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageRootPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        [String]
        $RegisterInTrustServer
    )
    
    $packageFileInfo = Get-InTrustPackageInfo -PackageRootPath $PackageRootPath -RelativePath "Agent" -PackageName "ADC_AGENT"
    if($packageFileInfo -ne $null)
    {
        $installArguments = Get-WindowsAgentInstallArguments -ServerName $RegisterInTrustServer
        return Retry-Command { Start-InstallationProgram -PackageFileInfo $packageFileInfo -ArgumentList $installArguments  } 
    }
    
    return -1    
}


function Install-InTrustLicense
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [string]
        $LicenseFullName = "C:\temp\License.asc"
    )
    
    Write-Host "`nTry to install new license" -ForegroundColor Green
    
    if(-not (Check-InTrustServicesStarted))
    {
        Write-Warning "Can't add license because InTrust service stopped"
        return -1
    }
    
    $InstallPath = Get-InTrustTopPath
    if($InstallPath -eq $null)
    {
        Write-Warning "Please Install InTrust before add license"
        return -1
    }

    try
    {
        $cfgBrowserDll = Get-ChildItem $InstallPath -Filter "Quest.InTrust.ConfigurationBrowser.dll" -Recurse -ErrorAction Ignore
        if($cfgBrowserDll.Count -eq 0)
        {
            Write-Warning "Not Found the Quest.InTrust.ConfigurationBrowser.dll in $InstallPath"
            return -1
        }
        
        [Reflection.Assembly]::LoadFrom($cfgBrowserDll.FullName) | Out-Null
        $cfgBrowser = New-Object Quest.InTrust.ConfigurationBrowser.InTrustConfigurationBrowser($false)
        $cfgBrowser.ConnectLocal()

        $licenseProcessor = New-Object Quest.InTrust.ConfigurationBrowser.Configuration.Licenses.InTrustLicenseInstaller -args $cfgBrowser
        $licenseProcessor.ProcessLicenseFile($LicenseFullName)
        $licenseProcessor.Dispose()
        $cfgBrowser.Dispose()
        
        Write-Host "Install new license successful" -ForegroundColor Green
    }
    catch
    {
        Write-Warning ($Error -join "`n")
        return -1
    }
    return 0
}

function Find-RuleByName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,
        
        [Quest.InTrust.ConfigurationBrowser.InTrustObject]
        $Group
    )

					$cfgBrowserDll = gci ${env:ProgramFiles(x86)} -Filter Quest.InTrust.ConfigurationBrowser.dll -Recurse -ErrorAction Ignore

					[Reflection.Assembly]::LoadFrom($cfgBrowserDll.FullName) | Out-Null

					$cfgBrowser = New-Object Quest.InTrust.ConfigurationBrowser.InTrustConfigurationBrowser($false)

					$cfgBrowser.ConnectLocal()



    if($Group -eq $null)
    {
        $parentGroup = $cfgBrowser.Configuration.Children["ITRTProcessingRuleGroups"]
    }
    else
    {
        $parentGroup = $Group
    }

    foreach($rule in $parentGroup.Properties["Rules"].Value)
    {
        if($rule.Name -match [regex]::escape("$Name")) 
        {
            return $rule
        }
    }

    foreach($child in $parentGroup.Children) 
    {
        $ruleInChild = Find-RuleByName -Name "$Name" -Group $child
        if ($ruleInChild) 
        {
            return $ruleInChild 
        }
    }
}

function  Enable-Rule
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RuleName,
        
        [parameter(parametersetname="Enable")]
        [switch]
        $Yes,
        
        [parameter(parametersetname="Disable")]
        [switch]
        $No
    )
					$cfgBrowserDll = gci ${env:ProgramFiles(x86)} -Filter Quest.InTrust.ConfigurationBrowser.dll -Recurse -ErrorAction Ignore

					[Reflection.Assembly]::LoadFrom($cfgBrowserDll.FullName) | Out-Null

					$cfgBrowser = New-Object Quest.InTrust.ConfigurationBrowser.InTrustConfigurationBrowser($false)

					$cfgBrowser.ConnectLocal()
	


    $_Rule = Find-RuleByName -Name "$RuleName" -Group $cfgBrowser.Configuration.Children["ITRTProcessingRuleGroups"]

    $switchStatus = {param($rule,$status) $rule.Properties["Enabled"].Value = $status; $rule.Update() }


    if($Yes)
    {
        $_Rule | %{ Invoke-Command $switchStatus -ArgumentList $_,1 }
    }
    else
    {
        $_Rule | %{ Invoke-Command $switchStatus -ArgumentList $_,0 }
    }

}

function Enable-Policy
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PolicyName,
        
        [parameter(parametersetname="Enable")]
        [switch]
        $Yes,
        
        [parameter(parametersetname="Disable")]
        [switch]
        $No
    )
					$cfgBrowserDll = gci ${env:ProgramFiles(x86)} -Filter Quest.InTrust.ConfigurationBrowser.dll -Recurse -ErrorAction Ignore

					[Reflection.Assembly]::LoadFrom($cfgBrowserDll.FullName) | Out-Null

					$cfgBrowser = New-Object Quest.InTrust.ConfigurationBrowser.InTrustConfigurationBrowser($false)

					$cfgBrowser.ConnectLocal()

    $_Policy = $cfgBrowser.Configuration.Children["ITRTPolicies"].Children.Item("$PolicyName")

    $switchStatus = {param($policy,$status) $policy.Properties["Enabled"].Value = $status; $policy.Update() }


    if($Yes)
    {
        $_Policy | %{ Invoke-Command $switchStatus -ArgumentList $_,1 }
    }
    else
    {
        $_Policy | %{ Invoke-Command $switchStatus -ArgumentList $_,0 }
    }
}

Export-ModuleMember Install-VCRedist,
                    Install-SQLNativeClient,
                    Install-InTrustServer,
                    Install-InTrustManager,
                    Install-InTrustDeploymentManager,
                    Install-InTrustRV,
                    Install-InTrustSDK,
					Install-InTrustIndexingTool,
                    Install-InTrustResourceKit,
                    Install-InTrustMonitoringConsole,
                    Install-InTrustKnowledgePortal,
                    Install-InTrustReportPacks,
                    Install-InTrustKnowledgePacks,
                    Install-InTrustDefaultKnowledgePacks,
                    Install-InTrustDefaultReportPacks,
                    Install-InTrustAdditionalReportPack,
                    Install-InTrustAdditionalKnowledgePack,
                    Install-InTrustITACS4SCOMPackage,
                    Install-InTrustITC4SCOMPackage,
                    Install-InTrustWindowsAgent,
                    Install-InTrustPackage,
                    Install-InTrustLicense,
					Find-RuleByName,
					Enable-Rule,
					Enable-Policy,
                    Stop-LocalInTrustProcesses,
					Start-LocalServicesInTrustDependsOn
