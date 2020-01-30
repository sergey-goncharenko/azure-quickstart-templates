
function Get-InTrustTopPath
{   
    try
    {
        $regkeyx86 = "HKLM:\SOFTWARE\Aelita\InTrust"
        $regkeyx64 = "HKLM:\SOFTWARE\Wow6432Node\Aelita\InTrust"
        $prop = $null

        if(Test-Path  $regkeyx86)
        {
            $prop = Get-ItemProperty $regkeyx86 -ErrorAction SilentlyContinue
        }

        if(Test-Path  $regkeyx64)
        {
            $prop = Get-ItemProperty $regkeyx64 -ErrorAction SilentlyContinue
        }

        if($prop -eq $null)
        {
            return $null            
        }

        return $prop.TopPath
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        write-host "Are you sure that product is installed?"
    }
    catch
    {
        #write-error $_
    }
    
    return $null
}


function Get-InTrustAgentInstallPath
{   
    try
    {
        $regkeyx86 = "HKLM:\SOFTWARE\Aelita\ADC"
        $regkeyx64 = "HKLM:\SOFTWARE\Wow6432Node\Aelita\ADC"
        $prop = $null

        if(Test-Path  $regkeyx86)
        {
            $prop = Get-ItemProperty $regkeyx86 -ErrorAction SilentlyContinue
        }

        if(Test-Path  $regkeyx64)
        {
            $prop = Get-ItemProperty $regkeyx64 -ErrorAction SilentlyContinue
        }

        if($prop -eq $null)
        {
            return $null            
        }

        return $prop.ADCCoreInstallPath
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        write-host "Are you sure that product is installed?"
    }
    catch
    {
        #write-error $_
    }
    
    return $null
}


function Invoke-CommandOnLocalPowershell64
{  
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,
        
        [String[]]
        $ImportModule,
        
        [Object[]]
        $ArgumentList
    )
    
    $machineName = hostname 
  
    try 
    {  
        # Note: The configuration name is what forces it to 64 bit.  
        $session = New-PSSession -ComputerName $machineName -ConfigurationName Microsoft.PowerShell  
    }
    catch 
    {  
        # Try to enable Remote Management on this machine.  
        winrm quickconfig -q -f  | out-null
          
        # Try again.  
        $session = New-PSSession -ComputerName $machineName -ConfigurationName Microsoft.PowerShell  
    }  
   
    try 
    {  
        # import ps1 as module
        foreach($module in $ImportModule)
        {
            Invoke-Command -Session $session -FilePath $module
        }
        
         # Now invoke our code in 64 bit PowerShell.  
        if($ArgumentList.Count -eq 0)
        {
            $result = Invoke-Command -Session $session -ScriptBlock $ScriptBlock   
        }

        if($ArgumentList.Count -ge 1)
        {
            $result = Invoke-Command -Session $session -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
        }
    } 
    finally 
    {  
        Remove-PSSession $session   | out-null
    }  
    return $result
}  


function Is-StartedService
{
    param
    (
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.ServiceProcess.ServiceController]
        $Service
    )
    
    return $Service.Status -eq 'Running'
}


function Is-ServiceStopped
{
    param
    (
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.ServiceProcess.ServiceController]
        $Service
    )
    
    return $Service.Status -eq 'Stopped'
}


function Is-ServiceDisabled
{
    param
    (
        [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.ServiceProcess.ServiceController]
        $Service
    )
    
    return $Service.StartType -eq 'Disabled'
}


function Retry-Command
{
    Param
    (
        [scriptblock]
        $CmdLine,

        [int]
        $Iters = 3
    )

    for($index = 0; $index -lt $Iters; $index++)
    {
        $result = & $CmdLine
        if( ($result -eq 0) -or ($result -eq 3010) )
        {
            Start-sleep -second 3
            return $result
        }
        
        Write-Warning "Failed, will retry after 10 seconds"
        Start-sleep -second 10
    }

    Write-Error "Failed after try $iters times"
    return $result
} 