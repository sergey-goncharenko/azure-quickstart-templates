
function Set-DefaultTargetPath
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TargetPath
    )
    
    #The default path which InTrust will install to
    $Script:DefaultTargetPath = $TargetPath
}
function Get-DefaultTargetPath
{
    #The default path which InTrust will install to
    return $Script:DefaultTargetPath
}

function Set-DefaultOrganizationCfg
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [bool]
        $JoinExistingOrganization,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationName,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OrganizationPassword 
    )
    
    #0 - Join to an existing InTrust organization. 1 - Create a new InTrust organization.
    if($JoinExistingOrganization)
    {
        $Script:DefaultConnectOrganizationMode = 0
    }
    else
    {
        $Script:DefaultConnectOrganizationMode = 1
    }    
    #The default Name of the InTrust organization.
    $Script:DefaultOrganizationName = $OrganizationName
    #Password for the InTrust organization.
    $Script:DefaultOrganizationPassword = $OrganizationPassword
}
function Get-DefaultConnectOrganizationMode
{
    return $Script:DefaultConnectOrganizationMode
}
function Get-DefaultOrganizationName
{
    return $Script:DefaultOrganizationName
}
function Get-DefaultOrganizationPassword
{
    return $Script:DefaultOrganizationPassword
}

function Set-DefaultServiceAccount
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceAccount,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceAccountPsw
    )
    
    #User account on whose behalf the InTrust Server services work
    $Script:DefaultServiceAccount = $ServiceAccount
    #Password of the user account on whose behalf the InTrust Server services work.
    $Script:DefaultServicePassword = $ServiceAccountPsw
}
function Get-DefaultServiceAccount
{
    return $Script:DefaultServiceAccount
}
function Get-DefaultServicePassword
{
    return $Script:DefaultServicePassword
}

function Set-DefaultInTrustPort
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $AdminPort,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $ListenPort
    )
        
    #Number of the port that InTrust Manager uses to connect to the InTrust server. The default is 8340.
    $Script:DefaultAdminPort = $AdminPort
    #Number of the port that agents use to communicate with the InTrust server. The default is 900.LISTEN
    $Script:DefaultListenPort = $ListenPort
}

function Get-DefaultAdminPort
{
    return $Script:DefaultAdminPort
}
function Get-DefaultListenPort
{
    return $Script:DefaultListenPort
}

function Set-DefaultNotification
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SMTPServer,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $SMTPPort,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MailSender,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MailTo,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NetSender 
    )
    
    #Name of the SMTP server that InTrust must use for notification messages.
    $Script:DefaultSMTPServer = $SMTPServer
    #Name of the port that InTrust must use for notification messages. The default is 25.
    $Script:DefaultSMTPPort = $SMTPPort
    #Identifies the sender of InTrust notification messages.
    $Script:DefaultMailSender = $MailSender
    #Email address of the default recipient of InTrust notification messages. 
    $Script:DefaultMailRecipient = $MailTo
    #This address becomes a property of the default notification operator.NETBIOS name of the computer for default operator.
    $Script:DefaultOperatorComputer = $NetSender
}
function Get-DefaultSMTPServer
{
    return $Script:DefaultSMTPServer
}
function Get-DefaultSMTPPort
{
    return $Script:DefaultSMTPPort
}
function Get-DefaultMailSender
{
    return $Script:DefaultMailSender
}
function Get-DefaultMailRecipient
{
    return $Script:DefaultMailRecipient
}
function Get-DefaultOperatorComputer
{
    return $Script:DefaultOperatorComputer
}


function Set-DefaultSQLConnect
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SQLServer ,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [bool]
        $SQLAuthenticationMode,
        
        [string]
        $SQLServerLogonName="",

        [string]
        $SQLServerPassword=""        
    )
    
    #Name of the SQL server where the configuration database must be located.
    $Script:DefaultSQLServer = $SQLServer 
    
    #Type of SQL Server connection to be used. 0 specifies that SQL Server authentication is used. 1 specifies a trusted connection.
    if($SQLAuthenticationMode)
    {
        $Script:DefaultAuthenticationMode = 0
    }
    else
    {
        $Script:DefaultAuthenticationMode = 1
    }
    
    #If DefaultAuthenticationMode is set to 0, specifies the user name for SQL Server authentication.
    $Script:DefaultSQLServerLogonName = $SQLServerLogonName
    #If DefaultAuthenticationMode is set to 0, specifies the user password for SQL Server authentication.
    $Script:DefaultSQLServerPassword = $SQLServerPassword
}
function Get-DefaultSQLServer
{
    return $Script:DefaultSQLServer
}
function Get-DefaultSQLAuthenticationMode
{
    return $Script:DefaultAuthenticationMode
}
function Get-DefaultSQLServerLogonName
{
    return $Script:DefaultSQLServerLogonName
}
function Get-DefaultSQLServerPassword
{
    return $Script:DefaultSQLServerPassword
}


function Set-DefaultDatabase
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigDb,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AuditDb,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AlertDb
    )

    #Name of the config database
    $Script:DefaultConfigDb = $ConfigDb
    #Name of the audit database
    $Script:DefaultAuditDb = $AuditDb
    #Name of the alert database
    $Script:DefaultAlertDb = $AlertDb
}
function Get-DefaultConfigDb
{
    return $Script:DefaultConfigDb
}
function Get-DefaultAuditDb
{
    return $Script:DefaultAuditDb
}
function Get-DefaultAlertDb
{
    return $Script:DefaultAlertDb
}

function Set-DefaultAutoDiscoverySettings
{
    param
    (
        [switch]
        $AutoDiscoveyConfigSetting,
        
        [switch]
        $AutoDiscoveySMTPSetting,
        
        [switch]
        $AutoDiscoveySRSSettings
    )
    
    #Auto Discover setting, enum valuse contains (InTrustCfgSettings = 1,InTrustSMTPSettings= 2,InTrustSRSSettings = 4)
    $Script:DefaultAutoDiscoverySetting = 0
    if($AutoDiscoveyConfigSetting)
    {
        $Script:DefaultAutoDiscoverySetting += 1
    }
    if($AutoDiscoveySMTPSetting)
    {
        $Script:DefaultAutoDiscoverySetting += 2
    }
    if($AutoDiscoveySRSSettings)
    {
        $Script:DefaultAutoDiscoverySetting += 4
    }
}

function Get-DefaultAutoDiscoverySetting
{
    return $Script:DefaultAutoDiscoverySetting
}

function Set-DefaultSRSPortal
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SRSServerName
    )

    #Path to a SRS server to be used as default for reporting jobs
    $Script:DefaultSRSPortal =  'http://{0}:80/ReportServer' -f ($SRSServerName)
}
function Get-DefaultSRSPortal
{
    return $Script:DefaultSRSPortal
}

function Set-DefaultInTrustReportWeb
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReportWebServer,
    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $ReportWebSiteNumber,    

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReportWebVirtualFolder,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $LocalReportFolder
    )

    #Path to a InTrust Knowledge Portal web application
    $Script:DefaultReportWebApplication = "http://$ReportWebServer:80/Report"
    #Microsoft IIS Web site number for InTrust Knowledge Portal component. 1 sets the default Web site.
    $Script:DefaultReportPortalWebSiteNumber = $ReportWebSiteNumber
    #Name of the virtual directory for the InTrust Knowledge Portal component 
    $Script:DefaultReportPortalWebVirtualFolder = $ReportWebVirtualFolder
    #Path to the Knowledge Portal home page.
    $Script:DefaultReportPortal = "http://$ReportWebServer/$DefaultReportPortalWebVirtualFolder"
    #Local path to a reports folder on current server.
    $Script:DefaultLocalReportFolder = $LocalReportFolder
}
function Get-DefaultReportWebApplication
{
    return $Script:DefaultReportWebApplication
}
function Get-DefaultReportPortalWebSiteNumber
{
    return $Script:DefaultReportPortalWebSiteNumber
}
function Get-DefaultReportPortalWebVirtualFolder
{
    return $Script:DefaultReportPortalWebVirtualFolder
}
function Get-DefaultReportPortal
{
    return $Script:DefaultReportPortal
}
function Get-DefaultLocalReportFolder
{
    return $Script:DefaultLocalReportFolder
}


function Set-DefaultMonitoringConsole
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $MonitoringConsoleSiteNumber,    

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MonitoringConsoleVirtualFolder
    )

    #Microsoft IIS Web site number for Monitoring console portal. 1 sets the default Web site.
    $Script:DefaultMonitoringConsoleWebSiteNumber = $MonitoringConsoleSiteNumber
    #Name of the virtual directory for Monitoring console portal
    $Script:DefaultMonitoringConsoleWebVirtualFolder = $MonitoringConsoleVirtualFolder
}
function Get-DefaultMonitoringConsoleWebSiteNumber
{
    return $Script:DefaultMonitoringConsoleWebSiteNumber
}
function Get-DefaultMonitoringConsoleWebVirtualFolder
{
    return $Script:DefaultMonitoringConsoleWebVirtualFolder
}


function Initialize-EnvironmentVariables
{
    param
    (
        [string]
        $commonPsw = "SGTest123",
        
        [string]
        $sqlServer = "localhost",

        [string]
        $sqlReportServer="localhost",        
		
		[string]
        $serviceAccount="$env:USERDOMAIN\$env:USERNAME"     
    )
    #$commonPsw = "SGTest123"

    $organizationName = hostname
    $organizationPassword = $commonPsw
    
    $serviceAccount = $serviceAccount
    $serviceAccountPassword = $commonPsw
    
    $configDBName = $env:COMPUTERNAME + '_CfgDb'
    $auditDBName = $env:COMPUTERNAME + '_AuditDb'
    $alertDBName = $env:COMPUTERNAME + '_AlertDb'
    
    $smtpServer = hostname
    $netSenderComputer = hostname
    
    #$sqlServer = hostname
    $sqlServerLoginAccount = $serviceAccount   #useless when AuthenticationMode is 1
    $sqlServerLoginPassward = $commonPsw                        #useless when AuthenticationMode is 1
    #$sqlReportServer =  hostname
    
    $intrustReportServer = $sqlReportServer
    
    $domainName = "$env:USERDOMAIN"
        
    
    Set-DefaultTargetPath -TargetPath  "${env:ProgramFiles(x86)}\Quest\InTrust"
    
    Set-DefaultOrganizationCfg -JoinExistingOrganization $false -OrganizationName  $organizationName -OrganizationPassword $organizationPassword
    
    Set-DefaultServiceAccount -ServiceAccount $serviceAccount -ServiceAccountPsw $serviceAccountPassword
    
    Set-DefaultInTrustPort -AdminPort 8340 -ListenPort 900
    
    Set-DefaultNotification -SMTPServer $smtpServer -SMTPPort 25 -MailSender "administrator@$domainName" -MailTo "operator@$domainName" -NetSender $netSenderComputer
    
    Set-DefaultSQLConnect -SQLServer $sqlServer -SQLAuthenticationMode $false -SQLServerLogonName $sqlServerLoginAccount -SQLServerPassword $sqlServerLoginPassward
    
    Set-DefaultDatabase -ConfigDb $configDBName -AuditDb $auditDBName -AlertDb $alertDBName
    
    Set-DefaultAutoDiscoverySettings #-AutoDiscoveySMTPSetting #-AutoDiscoveySRSSettings
    
    Set-DefaultSRSPortal -SRSServerName $sqlReportServer
    
    Set-DefaultInTrustReportWeb -ReportWebServer $intrustReportServer -ReportWebSiteNumber 1 -ReportWebVirtualFolder "QuestKnowledgePortal" -LocalReportFolder ("$Env:Public\Documents\Quest\Reports")
    
    Set-DefaultMonitoringConsole -MonitoringConsoleSiteNumber 1 -MonitoringConsoleVirtualFolder "ITMonitoring"

}

Initialize-EnvironmentVariables

Export-ModuleMember -Function Initialize-EnvironmentVariables,
                            Set-DefaultTargetPath,
                            Set-DefaultOrganizationCfg,
                            Set-DefaultServiceAccount,
                            Set-DefaultInTrustPort,
                            Set-DefaultNotification,
                            Set-DefaultSQLConnect,
                            Set-DefaultDatabase,
                            Set-DefaultAutoDiscoverySettings,
                            Set-DefaultSRSPortal,
                            Set-DefaultInTrustReportWeb,
                            Set-DefaultMonitoringConsole,
                            Get-DefaultTargetPath,
                            Get-DefaultConnectOrganizationMode,
                            Get-DefaultOrganizationName,
                            Get-DefaultOrganizationPassword,
                            Get-DefaultServiceAccount,
                            Get-DefaultServicePassword,
                            Get-DefaultAdminPort,
                            Get-DefaultListenPort,
                            Get-DefaultSMTPServer,
                            Get-DefaultSMTPPort,
                            Get-DefaultMailSender,
                            Get-DefaultMailRecipient,
                            Get-DefaultOperatorComputer,
                            Get-DefaultSQLServer,
                            Get-DefaultSQLAuthenticationMode,
                            Get-DefaultSQLServerLogonName,
                            Get-DefaultSQLServerPassword,
                            Get-DefaultConfigDb,
                            Get-DefaultAuditDb,
                            Get-DefaultAlertDb,
                            Get-DefaultAutoDiscoverySetting,
                            Get-DefaultSRSPortal,
                            Get-DefaultReportWebApplication,
                            Get-DefaultReportPortalWebSiteNumber,
                            Get-DefaultReportPortalWebVirtualFolder,
                            Get-DefaultReportPortal,
                            Get-DefaultLocalReportFolder,
                            Get-DefaultMonitoringConsoleWebSiteNumber,
                            Get-DefaultMonitoringConsoleWebVirtualFolder
                            