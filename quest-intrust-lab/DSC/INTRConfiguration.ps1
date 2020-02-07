configuration Configuration
{
   param
   (
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [String]$DCName,
        [Parameter(Mandatory)]
        [String]$INTRName,
        [Parameter(Mandatory)]
        [String]$ClientName,
        [Parameter(Mandatory)]
        [String]$PSName,
		[Parameter(Mandatory)]
		[String]$IntrUrl,
        [Parameter(Mandatory)]
		[String]$IntrLicUrl,
        [Parameter(Mandatory)]
        [String]$DNSIPAddress,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -ModuleName TemplateHelpDSC
	Import-DscResource -ModuleName xCredSSP
	
    $LogFolder = "TempLog"
	$CM = "IntrFull"
    $LogPath = "c:\$LogFolder"
    $DName = $DomainName.Split(".")[0]
    $DCComputerAccount = "$DName\$DCName$"
    $PSComputerAccount = "$DName\$PSName$"

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $PrimarySiteName = $PSName.split(".")[0] + "$"
    $INTRComputerAccount = "$DName\$INTRName$"
	$admname = $Admincreds.UserName
	$admpwd=$Admincreds.GetNetworkCredential().password

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        SetCustomPagingFile PagingSettings
        {
            Drive       = 'C:'
            InitialSize = '8192'
            MaximumSize = '8192'
        }

        DownloadSCCM DownLoadSCCM
        {
            CM = $CM
            ExtPath = $LogPath
			IntrUrl= $IntrUrl
			IntrLicUrl= $IntrLicUrl
            Ensure = "Present"
            DependsOn = "[SetCustomPagingFile]PagingSettings"
        }

        SetDNS DnsServerAddress
        {
            DNSIPAddress = $DNSIPAddress
            Ensure = "Present"
            DependsOn = "[DownloadSCCM]DownLoadSCCM"
        }

        InstallFeatureForSCCM InstallFeature
        {
            Name = "INTR"
            Role = "Distribution Point","Management Point"
            DependsOn = "[SetCustomPagingFile]PagingSettings"
        }

        WaitForDomainReady WaitForDomain
        {
            Ensure = "Present"
            DCName = $DCName
            DependsOn = "[SetDNS]DnsServerAddress"
        }

        JoinDomain JoinDomain
        {
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[WaitForDomainReady]WaitForDomain"
        }

        WaitForConfigurationFile WaitForPSJoinDomain
        {
            Role = "DC"
            MachineName = $DCName
            LogFolder = $LogFolder
            ReadNode = "PSJoinDomain"
            Ensure = "Present"
            DependsOn = "[JoinDomain]JoinDomain"
        }

        File ShareFolder
        {            
            DestinationPath = $LogPath     
            Type = 'Directory'            
            Ensure = 'Present'
            DependsOn = "[WaitForConfigurationFile]WaitForPSJoinDomain"
        }

        FileReadAccessShare DomainSMBShare
        {
            Name   = $LogFolder
            Path = $LogPath
            Account = $DCComputerAccount,$PSComputerAccount
            DependsOn = "[File]ShareFolder"
        }

        OpenFirewallPortForSCCM OpenFirewall
        {
            Name = "INTR"
            Role = "Distribution Point","Management Point"
            DependsOn = "[JoinDomain]JoinDomain"
        }

        AddUserToLocalAdminGroup AddADUserToLocalAdminGroup {
            Name = $admname
            DomainName = $DomainName
            DependsOn = "[FileReadAccessShare]DomainSMBShare"
        }

        AddUserToLocalAdminGroup AddADComputerToLocalAdminGroup {
            Name = "$PrimarySiteName"
            DomainName = $DomainName
            DependsOn = "[FileReadAccessShare]DomainSMBShare"
        }

        WriteConfigurationFile WriteINTRFinished
        {
            Role = "INTR"
            LogPath = $LogPath
            WriteNode = "INTRFinished"
            Status = "Passed"
            Ensure = "Present"
            DependsOn = "[AddUserToLocalAdminGroup]AddADUserToLocalAdminGroup","[AddUserToLocalAdminGroup]AddADComputerToLocalAdminGroup"
        }
		
		xCredSSP Server
        {
            Ensure = "Present"
            Role = "Server"
			DependsOn = "[WriteConfigurationFile]WriteINTRFinished"
        }
        xCredSSP Client
        {
            Ensure = "Present"
            Role = "Client"
            DelegateComputers = $PSName
			DependsOn = "[xCredSSP]Server"
        }
		
		InstallInTrust InstallInTrustTask
        {
            CM = $CM
            Adminpass = $admpwd
			DomainName = $DomainName
            Credential = $DomainCreds
			PSName = $PSName
			ScriptPath = $PSScriptRoot
            Ensure = "Present"
            DependsOn = "[xCredSSP]Client"
        }
		
#		RegisterTaskScheduler InstallAndUpdateSCCM
#        {
#            TaskName = "ScriptWorkFlow"
#            ScriptName = "ScriptWorkFlow2.ps1"
#            ScriptPath = $PSScriptRoot
#            ScriptArgument = "$DomainName $CM $DName\$($Admincreds.UserName) $INTRName $ClientName $($Admincreds.GetNetworkCredential().password)"
#            Ensure = "Present"
#            DependsOn = "[InstallInTrust]InstallInTrustTask"
##        }
    }
}