. "$PSScriptRoot\CommonUtilities.ps1"
$scriptFolder = split-path $PSScriptRoot -Parent
Import-module  "$PSScriptRoot\Utility.psm1" -DisableNameChecking  -Global -Force
import-module "$PSScriptRoot\SetInstallationParameters.psm1" -DisableNameChecking  -Global -Force


function Is-ServiceInTrustDependsOn
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName
    )
    
    $isServiceInTrustDependsOn = $false
    if( $ServiceName -eq "MSSQLSERVER")
    {
        $isServiceInTrustDependsOn = $true
    }
        
    return $isServiceInTrustDependsOn
}


function Is-InTrustService
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName
    )
    
    $isInTrustService = $false
    if( $ServiceName -eq "adcrpcs")
    {
        $isInTrustService = $true
    }
    if( $ServiceName -eq "itrt_svc")
    {
        $isInTrustService = $true
    }
    if( $ServiceName -eq "adcscm")
    {
        $isInTrustService = $true
    }
    
    return $isInTrustService
}


function Get-ServicesInTrustDependsOn
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    return Get-Service -ComputerName $ComputerName | where-object { Is-ServiceInTrustDependsOn $_.Name}
}


function Get-InTrustServices
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    return Get-Service -ComputerName $ComputerName | where-object { Is-InTrustService $_.Name}
}


function Start-DisabledService
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.ServiceProcess.ServiceController[]]
        $ServiceProcess
    )
    
    $isServiceStarted = $true
    foreach ($service in $ServiceProcess)
    {
        $serviceName = $service.Name
        
        if(Is-StartedService -Service $service)
        {
            write-Verbose "Trace: $serviceName service already started on $(hostName)"
            continue
        }
        
        if(Is-ServiceDisabled -Service $service)
        {
            write-Verbose "Trace: Set $serviceName service to Automatic mode on $(hostName)"
            $service | Set-Service -StartupType "Automatic"
        }
        
        write-Verbose "Trace: Start $serviceName service on $(hostName)"
            
        $service | Start-Service -WarningAction Ignore
        
        if(-Not(Is-StartedService -Service $service))
        {
            $isServiceStarted = $false
            Write-Error "Start $serviceName service failed on $(hostName)"
        }
        else
        {
            write-Verbose "Trace: Start $serviceName service successful on $(hostName)"
        }
    }
    
    return $isServiceStarted
}


function Start-InTrustServices
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    write-Verbose "Trace: Try to start services InTrust depends on $ComputerName"
    
    $intrustServices = Get-InTrustServices -ComputerName $ComputerName
    if($intrustServices -eq $null)
    {
        return $true
    }

    return Start-DisabledService -ServiceProcess $intrustServices 
}


function Start-IISService
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    write-Verbose "Trace: Try to start web service on $ComputerName"
    
    $webService = Get-Service -ComputerName $ComputerName | where-object { $_.Name -eq "W3SVC"}
    if($webService -eq $null)
    {
        return $true
    }

    return Start-DisabledService -ServiceProcess $webService
}


function Stop-ServiceSafe
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.ServiceProcess.ServiceController[]]
        $ServiceProcess
    )
    
    $isServicesStopped = $true
    foreach ($service in $ServiceProcess)
    {
        $serviceName = $service.Name
        if(Is-ServiceStopped -Service $service)
        {
            write-Verbose "Trace: $serviceName service already stopped on $(hostName)"
            continue
        }
        
        write-Verbose "Trace: Stop $serviceName service on $(hostName)"
        $service | Stop-Service -Force -WarningAction Ignore
        
        if(-not (Is-ServiceDisabled -Service $service))
        {
            write-Verbose "Trace: Set $serviceName service to Disabled mode on $(hostName)"
            $service | Set-Service -StartupType "Disabled"
        }
        
        if(-Not(Is-ServiceStopped -Service $service))
        {
            $isServicesStopped = $false
            Write-Error "Stop $serviceName service failed on $(hostName)"
        }
        else
        {
            write-Verbose "Trace: Stop $serviceName service successful on $(hostName)"
        }
    }
    
    return $isServicesStopped
}

    
function Stop-InTrustServices
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    write-Verbose "Trace: Try to stop InTrust service before upgrade/install on $ComputerName"
    
    $intrustServices = Get-InTrustServices -ComputerName $ComputerName
    if($intrustServices -eq $null)
    {
        write-Verbose "Trace: Not found installed InTrust service on $ComputerName lab"
        return $true
    }
    
    return Stop-ServiceSafe -ServiceProcess $intrustServices
}


function Stop-IISService
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    write-Verbose "Trace: Try to stop web service before upgrade/install on $ComputerName"
    
    $webService = Get-Service -ComputerName $ComputerName | where-object { $_.Name -eq "W3SVC"}
    if($webService -eq $null)
    {
        return $true
    }

    return Stop-ServiceSafe -ServiceProcess $webService
}


function Is-InTrustModule
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ModuleFileName
    )

    $installPath = Get-InTrustTopPath
    $agentPath = Get-InTrustAgentInstallPath
    
    $commonPath = "${env:CommonProgramFiles(x86)}\Quest"
    $sharedPath = "${env:CommonProgramFiles(x86)}\Quest Shared"
    $defaultInstallPath =  "${env:ProgramFiles(x86)}\Quest"
    
    
    $isInTrustmodule = $false
    if( $ModuleFileName -like "$installPath*" -and $installPath -ne $null)
    {
        $isInTrustmodule = $true
    }
    if( $ModuleFileName -like "$commonPath*")
    {
        $isInTrustmodule = $true
    }
    if( $ModuleFileName -like "$sharedPath*")
    {
        $isInTrustmodule = $true
    }
    if( $ModuleFileName -like "$defaultInstallPath*")
    {
        $isInTrustmodule = $true
    }
    if( $ModuleFileName -like "$agentPath*" -and $agentPath -ne $null)
    {
        $isInTrustmodule = $true
    }
    
    return $isInTrustmodule
}


function Is-InTrustProcess
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Diagnostics.Process]
        $Process
    )
    
    foreach($module in $Process.Modules)
    {
        if(Is-InTrustModule -ModuleFileName $module.FileName)
        {
            return $true
        }
    }

    return $false
}


function Get-InTrustProcess
{
    return Get-Process | where-object {Is-InTrustProcess $_}
}


function Stop-InTrustProcess
{
    $processBit = "32bit"
    if([IntPtr]::size -eq 8)
    {
        $processBit = "64bit"
    }
    
    write-Verbose "Trace: Try to stop $processBit InTrust process on $(hostName)"
    
    $intrustProcess = Get-InTrustProcess 
    if($intrustProcess -eq $null)
    {
        write-Verbose "Trace: Not found running $processBit InTrust process on $(hostName)"
        return $true
    }

    foreach ($process in $intrustProcess)
    {
        $processName = $process.Name
        if($process.HasExited)
        {
            write-Verbose "Trace: $processName($processBit) process already stopped on $(hostName)"
            continue
        }
        
        $process | Stop-Process -Force
        
        if($process.HasExited)
        {
            write-Verbose "Trace: $processName($processBit) process be stopped on $(hostName)"
        }
        else
        {
            write-Verbose "Trace: $processName($processBit) process can't stopped.$($process.HasExited) on $(hostName)"
        }
    }

    $noInTrustProcess = Get-InTrustProcess 
    if($noInTrustProcess -ne $null)
    {
        foreach ($process in $noInTrustProcess)
        {
            write-Verbose "Trace: ($process.Name)($processBit) process still in process list on $(hostName)"
        }
        return $false
    }
    
    return $true
}


function Wait-InTrustProcessesStopped
{
    Param
    (
        [switch]
        $32BitProcess = $true
    )
    
    $_stopInTrustProcess = 
    {
        #InTrust service can start some process as schedule task
        #64bitnew_RV can start com+ service to communicate with 32bit process
        $inTrustServiceStopped = Wait-FunctionFinshed {
            return Stop-InTrustServices
        } -Iters 30 -Timeout 2 -NoException 
        
        $webServiceStopped = Wait-FunctionFinshed {
            return Stop-IISService
        } -Iters 30 -Timeout 2 -NoException 
        
        #stop new_RV,ITM,IDM,Utility,Powershell process 
        #some powershell process maybe load InTrust Dll
        #Utility can be started by InTrust service
        $inTrustProcessStopped = Wait-FunctionFinshed {
            return Stop-InTrustProcess
        } -Iters 30 -Timeout 2 -NoException 
        
        #re-stop the com+ service process which started by new_RV
        $inTrustServiceStopped2 = Wait-FunctionFinshed {
            return Stop-InTrustServices
        } -Iters 30 -Timeout 2 -NoException 
        
        return ($inTrustServiceStopped -and $webServiceStopped -and $inTrustProcessStopped -and $inTrustServiceStopped2)
    }
    
    $scriptFolder = split-path $PSScriptRoot -Parent
    $importfile1 = "$scriptFolder\Utility\Common.ps1"
    $importfile2 = "$scriptFolder\Install\WaitInTrustInstall.ps1"
    [String[]] $importfile = @($importfile1,$importfile2)
        
    if($32BitProcess)
    {
        return & $_stopInTrustProcess
    }
    else
    {
        return Invoke-CommandOnLocalPowershell64 -ScriptBlock $_stopInTrustProcess -ImportModule $importfile
    }
}

         
function Stop-LocalInTrustProcesses
{
    write-Host "Waiting for stop all InTrust process on $(hostName) before upgrade "  
    
    $local64ProcessStopped = Wait-InTrustProcessesStopped -32BitProcess:$false
    $local32ProcessStopped = Wait-InTrustProcessesStopped -32BitProcess:$true
    
    return ($local64ProcessStopped -and $local32ProcessStopped)
}


function Start-LocalInTrustServices
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    $inTrustServiceStarted = Wait-FunctionFinshed {
        return Start-InTrustServices -ComputerName $ComputerName
    } -Iters 30 -Timeout 2 -NoException
    
    $webServiceStarted = Wait-FunctionFinshed {
        return Start-IISService -ComputerName $ComputerName
    } -Iters 30 -Timeout 2 -NoException
    
    return ($inTrustServiceStarted -and $webServiceStarted)
}


function Start-ServicesInTrustDependsOn
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    write-Verbose "Trace: Try to start services InTrust depends on $ComputerName"
    
    $intrustServices = Get-ServicesInTrustDependsOn -ComputerName $ComputerName
    if($intrustServices -eq $null)
    {
        return $true
    }
    
    return Start-DisabledService -ServiceProcess $intrustServices
}


function Start-LocalServicesInTrustDependsOn
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    return Wait-FunctionFinshed {
        return Start-ServicesInTrustDependsOn  -ComputerName $ComputerName
    } -Iters 30 -Timeout 2 -NoException 
}


function Check-InTrustServicesStarted
{
    param
    (
        [string]
        $ComputerName = (hostname)
    )
    
    write-Verbose "Trace: Try to stop InTrust service before upgrade/install on $ComputerName"
    
    $intrustServices = Get-InTrustServices -ComputerName $ComputerName
    if($intrustServices -eq $null)
    {
        write-Verbose "Trace: Not found installed InTrust service on $ComputerName lab"
        return $false
    }
    
    $allServiceNotStop = $true
    foreach($service in $intrustServices)
    {
        if($service.Status -ne "Running")
        {
            $serviceDispalyName = $service.DisplayName
            
            $allServiceNotStop = $false
            write-warning "Please run $serviceDispalyName service before next step"
        }
    }
    
    return $allServiceNotStop    
}


function Get-InTrustPackageInfo
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageRootPath,
        
        [string]
        $RelativePath,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName,
        
        [switch]
        $LiteralName
    )
    
    
    if($LiteralName)
    {
        $filePattern = "$PackageName"
    }
    else
    {
        $filePattern = "*$PackageName*.msi"
    }

    $packageFullFolder = Join-Path $PackageRootPath $RelativePath
    if(-not (Test-Path $packageFullFolder))
    {
        Write-Error "The $packageFullFolder does not exist"
        return $null
    }
    
    $packageInfo =  Get-ChildItem -Path $packageFullFolder -Filter $filePattern -Recurse
    if($packageInfo.count -eq 1)
    { 
        return $packageInfo
    }
    elseif($packageInfo.count -eq 0)
    {
        if($PackageName -ne "")
        {
            Write-Error "Not Found the $filePattern in the $packageFullFolder"
        }
        else
        {
            Write-Error "Not Found any file in the $packageFullFolder"
        }
    }
    else
    {
        return $packageInfo
    }
    
    return $null
}


function Get-InstallLogFile
{
    param
    (
        [ValidateNotNullOrEmpty()] 
        [System.IO.FileSystemInfo]
        $PackageFileInfo
    )
    
    $logFolder = split-path $PackageFileInfo.DirectoryName
    $currentDate = get-date -Format "yyyyMMdd-HHmmss"
    
    $logFileName = $PackageFileInfo.BaseName
    $logFile = Join-Path $logFolder "\$LogFileName-$currentDate.log"
    if(Test-Path $logFile)
    {
        Remove-Item $logFile -Force
    }
    return $logFile
}


function Get-BasicInstallCmdline
{
    param
    (
        [System.IO.FileSystemInfo]
        $PackageFileInfo
    )
  
    if($PackageFileInfo.Extension -eq ".exe")
    {
        $cmdline = "/install /passive"
    }
    elseif($PackageFileInfo.Extension -eq ".msi")
    {
        #$cmdline  = " /quiet"  
		$cmdline  = " /qb"
        $cmdline += " /l*v """  + (Get-InstallLogFile $PackageFileInfo) + """"
        $cmdline += " /i """ + $PackageFileInfo.FullName + """"
    }

    return $cmdline 
}


function Get-PackageExecutor
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileSystemInfo]
        $PackageFileInfo
    )
    
    if($PackageFileInfo.Extension -eq ".exe")
    {
        return $PackageFileInfo[0].FullName
    }
    elseif($PackageFileInfo.Extension -eq ".msi")
    {
        return "msiexec.exe"
    }
    
    return ""
    
}    


function Start-InstallationProgram
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileSystemInfo]
        $PackageFileInfo,
        
        [string]
        $ArgumentList = "", 
        
        [string]
        $WorkingDirectory,
		
		[string]
		$username ="",
		
		[System.Management.Automation.PSCredential] 
		$Credential
		
    )
    
    $FilePath = Get-PackageExecutor -PackageFileInfo $PackageFileInfo
    if( (-not (Test-Path $FilePath)) -and (-not (Get-Command $FilePath)) )
    {
         Write-Error "$FilePath does not exist" 
         return -1
    }
    
    $installArguments = Get-BasicInstallCmdline $PackageFileInfo
    $installArguments += $ArgumentList
    
    $packageName = $PackageFileInfo.Name
    $BaseName = $PackageFileInfo.BaseName    
    $directoryName =  $PackageFileInfo.DirectoryName                             
    
    $currentTime = get-date
    $currentDate = $currentTime.ToString("yyyyMMdd-HHmmss")
    $cmdFileName = Join-Path $directoryName "\$BaseName-$($currentTime.ToString("yyyyMMdd-HHmmss")).bat"
    "$FilePath $installArguments" | out-file "$cmdFileName"
    
    Write-Host "`n[$($currentTime.ToString("yyyyMMdd-HH:mm:ss"))] Start to install $packageName on $(hostName) with the following cmdline:`n"   -ForegroundColor Green
    Write-Host "$FilePath $installArguments"

    # return 0
    try
    {
        $startInfo = New-Object Diagnostics.ProcessStartInfo($FilePath, $installArguments)
        if ($WorkingDirectory)
        {
            $startInfo.WorkingDirectory = $WorkingDirectory
        }
        $startInfo.RedirectStandardError = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.UseShellExecute = $false
		if($username -ne "")
		{
			$startInfo.Username = $username
			$startInfo.Domain = $Credential.GetNetworkCredential().Domain
            $startInfo.Password = $Credential.Password
		}
		
		
        $process = [diagnostics.process]::start($startInfo)

        $process.BeginOutputReadLine()
        $process.StandardError.ReadToEnd() | Out-Null
        
        $hasClosed = $process.WaitForExit(600*1000)
        if($hasClosed -eq $false)
        {
            Write-Warning "Timeout during install $packageName,stop the process and try again later"    
            $process.Kill
            $process.Close
            return -1
        }
    }
    catch
    {
        Write-Warning "Met exception duiring install $packageName,try again later" 
        return -1
    }
            
    if (($process.ExitCode -ne 0) -or (-not $process.HasExited))
    {
        if($process.ExitCode -eq 1605)
        {
            Write-Warning "Already uninstalled (product not found 1605 status)"    
        }
        else 
        {
            if ($process.ExitCode -eq -1) 
            {
                Write-Warning "Installation of $BaseName has exit code = -1"
            }
            else 
            {
                if ($process.ExitCode -eq 3010) 
                {
                    write-warning "Restart $hostName computer after install $packageName"

                    return $process.ExitCode
                }
                elseif($process.ExitCode -eq 1618)
                {
                    write-warning "Another installation is already in progress,re-try after 10 seconds"
                    sleep -second 10
                }
                else
                {
                    Write-warning "Installation of $BaseName failed. Exit code = $($process.ExitCode) ; Has Exited = $($process.HasExited)"
                }
            }
        }
    }
    else
    {
        write-host "Success to install $packageName on $hostName" -ForegroundColor Green
    }
    
    return $process.ExitCode
}


function  Get-TargetPathSetting
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallPathParamName = "PF_INTRUST_TOP",
        
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallPathRelativeValue = ""
    )
    
    $defaultInstallPath = Get-DefaultTargetPath
    $destPath = Join-Path $defaultInstallPath $InstallPathRelativeValue

    #New Parameter:Full path to the folder where InTrust component must be installed. Normally, %ProgramFiles%\Quest\InTrust. Note that InTrust is a 32-bit app, %ProgramFiles% will be resolved to Program Files (x86) during installation.
    return " " + $InstallPathParamName + "=""" + $destPath + """"
}


function Get-OrganizationSettings
{
    $ConnectOrganizationMode = Get-DefaultConnectOrganizationMode
    $OrganizationName = Get-DefaultOrganizationName
    $OrganizationPassword = Get-DefaultOrganizationPassword
    
    #New Parameter:Connect to an InTrust organization; 0 - Join to an existing InTrust organization. 1 - Create a new InTrust organization.
    $parameter += ' {0}="{1}"' -f ("ADC_NEW_CONFIGURATION", $ConnectOrganizationMode)
    #Name of the InTrust organization.
    $parameter += ' {0}="{1}"' -f ("ADC_ORGANIZATION_NAME", $OrganizationName)
    #New Parameter: Password for the InTrust organization
    $parameter += ' {0}="{1}"' -f ("ADC_ORGANIZATION_PASSWORD", $OrganizationPassword)
    #New Parameter: Confirm the password for the InTrust organization
    $parameter += ' {0}="{1}"' -f ("ADC_ORGANIZATION_PASSWORD2", $OrganizationPassword)

    return $parameter
}


function Get-CommunicationSettings
{

    $AdministratorPort = Get-DefaultAdminPort
    $ListenPort = Get-DefaultListenPort
        
    #New Parameter:
    $parameter += ' {0}="{1}"' -f ("ADC_PROP_INITIALIZED", 0)
    #New Parameter:Number of the port that InTrust Manager uses to connect to the InTrust server. The default is 8340.
    $parameter += ' {0}="{1}"' -f ("ADC_SERVER_ADMIN_PORT", $AdministratorPort)
    #New Parameter:Number of the port that agents use to communicate with the InTrust server. The default is 900.
    $parameter += ' {0}="{1}"' -f ("ADC_SERVER_LISTENING_PORT", $ListenPort)

    return $parameter
}


function Get-MailSettings
{
    $SMTPServer = Get-DefaultSMTPServer
    $SMTPPort = Get-DefaultSMTPPort
    $MAIL_FROM = Get-DefaultMailSender
    $MAIL_TO = Get-DefaultMailRecipient
    $Operator_Computer = Get-DefaultOperatorComputer
        
    #Email address of the recipient of InTrust notification messages. 
    $parameter += ' {0}="{1}"' -f ("ADC_SMTP_SERVER", $SMTPServer)
    #New Parameter:Name of the port that InTrust must use for notification messages. The default is 25.    
    $parameter += ' {0}="{1}"' -f ("ADC_SMTP_PORT", $SMTPPort)
    #Identifies the sender of InTrust notification messages.(MAIL_FROM)
    $parameter += ' {0}="{1}"' -f ("ADC_SMTP_FROM_EMAIL", $MAIL_FROM)
    #New Parameter:Name of the SMTP server that InTrust must use for notification messages.(MAIL_TO)
    $parameter += ' {0}="{1}"' -f ("ADC_SMTP_EMAIL", $MAIL_TO)
    #New Parameter:
    $parameter += ' {0}="{1}"' -f ("ADC_OPERATOR_COMPUTER", $Operator_Computer)
    
    return $parameter
}


function Get-ConfigurationDBSettings
{
    $DBServer = Get-DefaultSQLServer
    $DBName = Get-DefaultConfigDb
    $DBAuthType = Get-DefaultSQLAuthenticationMode
    $LogonName = Get-DefaultSQLServerLogonName
    $Password = Get-DefaultSQLServerPassword
        
    #Name of the SQL server where the configuration database must be located.
    $parameter += ' {0}="{1}"' -f ("ADC_SQL_SERVER", $DBServer)
    #Name of the configuration database.
    $parameter += ' {0}="{1}"' -f ("ADC_SQL_DB_NAME", $DBName)
    
    #New Parameter: 0 specifies that SQL Server authentication is used. 1 specifies use windows authentication connection
    $parameter += ' {0}="{1}"' -f ("ADC_SQL_TYPE", $DBAuthType)
    if($DBAuthType -eq 0)
    {   
        #In Cmd file, if DBAuthType is  0, not write the sql user name and password
        #If SQL_AUTH_TYPE is set to 0, specifies the user name for SQL Server authentication
        $parameter += ' {0}="{1}"' -f ("ADC_SQL_USERNAME", $LogonName)
        #If SQL_AUTH_TYPE is set to 0, specifies the user name for SQL Server authentication
        $parameter += ' {0}="{1}"' -f ("ADC_SQL_PASSWD", $Password)
    }
    else
    {
        #If ITRT_DB_LOGIN_TRUSTED is set to 0, specifies the user name for SQL Server authentication.
        $parameter += ' {0}="{1}"' -f ("ADC_SQL_USERNAME", "$LogonName")
    }

    return $parameter
}


function Get-AuditDBSettings
{
    $DBServer = Get-DefaultSQLServer
    $DBName = Get-DefaultAuditDb
    $DBAuthType = Get-DefaultSQLAuthenticationMode
    $LogonName = Get-DefaultSQLServerLogonName
    $Password = Get-DefaultSQLServerPassword
    
    #Name of the SQL server where the audit database must be located.
    $parameter += ' {0}="{1}"' -f ("ITAUD_SQL_SERVER", $DBServer)
    #Name of the audit database.
    $parameter += ' {0}="{1}"' -f ("ITAUD_SQL_DATABASE", $DBName)
    
    #New Parameter:0 specifies that SQL Server authentication is used. 1 specifies use windows authentication connection
    $parameter += ' {0}="{1}"' -f ("ITAUD_SQL_IS_TRUSTED", $DBAuthType)
    if($DBAuthType -eq 0)
    {
        #In Cmd file, if DBAuthType is  0, not write the sql user name and password
        #If ITAUD_SQL_IS_TRUSTED is set to 0, specifies the user name for SQL Server authentication.
        $parameter += ' {0}="{1}"' -f ("ITAUD_SQL_USERNAME", $LogonName)
        #If ITAUD_SQL_IS_TRUSTED is set to 0, specifies the user name for SQL Server authentication.
        $parameter += ' {0}="{1}"' -f ("ITAUD_SQL_PASSWORD", $Password)
    }
    else
    {
        #If ITRT_DB_LOGIN_TRUSTED is set to 0, specifies the user name for SQL Server authentication.
        $parameter += ' {0}="{1}"' -f ("ITAUD_SQL_USERNAME", "$LogonName")
    }
    
    return $parameter
}


function Get-AlertDBSettings
{
    $DBServer = Get-DefaultSQLServer
    $DBName = Get-DefaultAlertDb
    $DBAuthType = Get-DefaultSQLAuthenticationMode
    $LogonName = Get-DefaultSQLServerLogonName
    $Password = Get-DefaultSQLServerPassword
    
    #Name of the SQL server where the alert database must be located.
    $parameter += ' {0}="{1}"' -f ("ITRT_DB_SERVERNAME", $DBServer)
    #Name of the alert database.
    $parameter += ' {0}="{1}"' -f ("ITRT_DB_DATABASENAME", $DBName)

    #New Parameter:0 specifies that SQL Server authentication is used. 1 specifies use windows authentication connection.
    $parameter += ' {0}="{1}"' -f ("ITRT_DB_LOGIN_TRUSTED", $DBAuthType)
    if($DBAuthType -eq 0)
    {
        #In Cmd file, if DBAuthType is  0, not write the sql user name and password
        #If ITRT_DB_LOGIN_TRUSTED is set to 0, specifies the user name for SQL Server authentication.
        $parameter += ' {0}="{1}"' -f ("ITRT_DB_LOGIN_UID", $LogonName)
        #If ITRT_DB_LOGIN_TRUSTED is set to 0, specifies the user name for SQL Server authentication
        $parameter += ' {0}="{1}"' -f ("ITRT_DB_LOGIN_PASSWORD", $Password)
    }
    else
    {
        #If ITRT_DB_LOGIN_TRUSTED is set to 0, specifies the user name for SQL Server authentication.
        $parameter += ' {0}="{1}"' -f ("ITRT_DB_LOGIN_UID", "$LogonName")
    }
    
    return $parameter
}


function Get-ServicesAccountSettings
{
    $UserName = Get-DefaultServiceAccount
    $Password = Get-DefaultServicePassword

    #User account on whose behalf the adcrpcs services work.
    $parameter += ' {0}="{1}"' -f ("ADC_USERNAME", $UserName)
    #Password of the user account on whose behalf the adcrpcs services work
    $parameter += ' {0}="{1}"' -f ("ADC_PASSWORD", $Password)
    
    #User account on whose behalf the itrt_svc services work.
    $parameter += ' {0}="{1}"' -f ("ITRT_SVC_LOGINNAME", $UserName)
    #Password of the user account on whose behalf the itrt_svc services work.
    $parameter += ' {0}="{1}"' -f ("ITRT_SVC_PASSWORD", $Password)
    
    return $parameter
}


function Get-ReportingSettings
{
    $SQLReportingServicesURL = Get-DefaultSRSPortal
    $ReportPortal = Get-DefaultReportPortal
    $LocalReportFolder = Get-DefaultLocalReportFolder
        
    #Not implement parameter
    #SQL Server Reporting Services URL (Path to a SRS server to be used as default for reporting jobs)
    $parameter += ' {0}="{1}"' -f ("IT_REPORTING_DEFAULT_SRS", $SQLReportingServicesURL)
    
    #Path to the Knowledge Portal home page.
    $parameter += ' {0}="{1}"' -f ("IT_REPORTING_DEFAULT_QRS", $ReportPortal)
    
    #Local path to a reports folder on current server.
    $parameter += ' {0}="{1}"' -f ("PF_IT_REPORTING_DEFAULT_REPORT_SHARE", $LocalReportFolder)
    
    return $parameter
}


function Get-AdvancedSettings
{
    $AutoDiscoverySetting = Get-DefaultAutoDiscoverySetting

    #$parameter += ' {0}="{1}"' -f ("AE_IGNORE_SETUSERRIGHTS_RESULT", 1)
    $parameter += ' {0}="{1}"' -f ("IT_DEF_SETTINGS_INITIALIZED", 1)
    $parameter += ' {0}="{1}"' -f ("IT_SQL_SETTINGS_INITIALIZED", 1)
    #$parameter += ' {0}="{1}"' -f ("IT_SMTP_SETTINGS_INITIALIZED", 1)
    #$parameter += ' {0}="{1}"' -f ("IT_SRS_SETTINGS_INITIALIZED", 1)
    #$parameter += ' {0}="{1}"' -f ("IT_SRS_LOCAL_SETTINGS_INITIALIZED", 1)
        
    #InTrustCfgSettings = 1,InTrustSMTPSettings= 2,InTrustSRSSettings = 4
    #$parameter += ' {0}="{1}"' -f ("AE_AUTO_DISCOVERY_PAGES", $AutoDiscoverySetting)

    #$parameter += ' {0}="{1}"' -f ("REBOOT", "ReallySuppress")
    
    #Participation in the Software Improvement Program,0 - do not participate. 1 - participate.
    $parameter += ' {0}="{1}"' -f ("SIP_OPTIN", "#0")

    return $parameter
}


function Get-SeverInstallArguments
{
    $installArguments = Get-TargetPathSetting
    $installArguments += Get-OrganizationSettings
    $installArguments += Get-CommunicationSettings
    $installArguments += Get-MailSettings
    $installArguments += Get-ServicesAccountSettings  

    $installArguments += Get-ConfigurationDBSettings
    $installArguments += Get-AuditDBSettings
    $installArguments += Get-AlertDBSettings
    $installArguments += Get-ReportingSettings
    $installArguments += Get-AdvancedSettings
    
    return $installArguments
}


function Get-InTrustMonitoringConsoleSettings
{
    param
    (
        [ValidateNotNullOrEmpty()]
        [int]
        $ChangeSetting = 1
    )

    $IISSiteNumber = Get-DefaultMonitoringConsoleWebSiteNumber
    $IISVDir = Get-DefaultMonitoringConsoleWebVirtualFolder
        
    #
    $parameter += ' {0}="{1}"' -f ("IT8_CHANGE_DEF_SETTINGS", $ChangeSetting)
    #Microsoft IIS Web site number. 1 sets the default Web site..
    $parameter += ' {0}="{1}"' -f ("IT8_WEB_IIS_SITE", $IISSiteNumber)
    #Name of the virtual directory.
    $parameter += ' {0}="{1}"' -f ("IT8_WEB_IIS_VDIR", $IISVDir)

    return $parameter
}


function Get-MonitoringConsoleInstallArguments
{
    $installArguments = Get-TargetPathSetting -InstallPathParamName "PF_RTWEBCONSOLE" -InstallPathRelativeValue "\Monitoring Console" 
    $installArguments += Get-InTrustMonitoringConsoleSettings
    
    return $installArguments
}


function Get-InTrustKnowledgePortalSettings
{
    $ServiceUserName = Get-DefaultServiceAccount
    $ServicePassword = Get-DefaultServicePassword
        
    $RSServiceUrl = Get-DefaultSRSPortal
    $RSConsoleUrl = Get-DefaultReportWebApplication
    $IISSite = Get-DefaultReportPortalWebSiteNumber
    $IISVDir = Get-DefaultReportPortalWebVirtualFolder
        
    #User account on whose behalf the InTrust Server services work.
    $parameter += ' {0}="{1}"' -f ("CWP_USER_DEF", $ServiceUserName)
    #Password of the user account on whose behalf the InTrust Server services work.
    $parameter += ' {0}="{1}"' -f ("CWP_PWD", $ServicePassword)
    #Path to a SRS server to be used as default for reporting jobs.
    $parameter += ' {0}="{1}"' -f ("CWP_RS_SERVICE_URL_DEF", $RSServiceUrl)
    #Path to a InTrust Knowledge Portal web application.
    $parameter += ' {0}="{1}"' -f ("CWP_RS_CONSOLE_URL_DEF", $RSConsoleUrl)
    #Microsoft IIS Web site number for the InTrust Knowledge Portal component. 1 sets the default Web site.
    $parameter += ' {0}="{1}"' -f ("CWP_IIS_SITE_DEF", $IISSite)
    #Name of the virtual directory for the InTrust Knowledge Portal component 
    $parameter += ' {0}="{1}"' -f ("CWP_IIS_VDIR_DEF", $IISVDir)
    $parameter += ' {0}="{1}"' -f ("CWP_RS_SERVICE_TIMEOUT", 36000)

    return $parameter
}


function Get-KnowledgePortalInstallArguments
{
    $installArguments = Get-TargetPathSetting 
    $installArguments += Get-TargetPathSetting -InstallPathParamName "PF_CWP_JAGUAR" -InstallPathRelativeValue "\Knowledge Portal\" 
    $installArguments += Get-InTrustKnowledgePortalSettings
        
    return $installArguments
}


function Get-WindowsAgentInstallArguments
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        [string]
        $ServerName,

        [ValidateNotNullOrEmpty()]
        [bool]
        $Register = $False
    )

    $AgentPort = Get-DefaultListenPort
    $OrganizationPassword = Get-DefaultOrganizationPassword
        
    #Specify InTrust Server name for agent installation.
    $parameter += ' {0}="{1}"' -f ("SERVER", $ServerName)
    #Number of the port that agents use to communicate with the InTrust server. The default is 900.
    $parameter += ' {0}="{1}"' -f ("PORT", $AgentPort)
    #Password for the InTrust organization.
    $parameter += ' {0}="{1}"' -f ("PASSWORD", $OrganizationPassword)
    #REGISTER_AGENT for registry the agent to server
    if($Register)
    {
        $parameter += ' {0}="{1}"' -f ("REGISTER_AGENT", 1)
    }
    else
    {
        $parameter += ' {0}="{1}"' -f ("REGISTER_AGENT", 0)
    }
    
    return $parameter
}
