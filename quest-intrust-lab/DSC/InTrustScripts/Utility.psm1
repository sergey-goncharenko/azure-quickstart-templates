function Get-FilePathWithoutExtension
{
	param
	(
		[Parameter(Mandatory=$True,ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$FullFileName
	)
	
	$filePath = [io.path]::GetDirectoryName($FullFileName)
	$fileNameWithoutExtension = [io.path]::GetFileNameWithoutExtension($FullFileName)
	return join-path $filePath $fileNameWithoutExtension
}


function Wait-FunctionFinshed([Parameter(Mandatory=$true)][ScriptBlock] $sb, [int]$Iters, [int]$Timeout, [scriptblock]$ErrorCallback, [switch]$NoException, [switch]$Trace)
{
    $lastResult = $null
    $i = $Iters
    while(($i--) -gt 0){
        if($Trace){
            Write-Host ("Wait-FunctionFinshed: Execute iters: {0}/$Iters" -f ($Iters - $i))
        }
        if($ErrorCallback -and !(& $ErrorCallback)){ return $lastResult }
        $lastResult = &$sb
        if($lastResult) { return $lastResult }
        sleep -m (1000*$timeout); 
    }
    $trace = "
        Timeout reached after $Iters iterations by $Timeout seconds
        ==========Begin to trace the function: Wait-FunctionFinshed ==========
        $sb
        ==========End to trace the function: Wait-FunctionFinshed ==========
        "
    if (-not $NoException)
    {
        Write-Error $trace
    } 
    else 
    {
        Write-Host $trace
    }
    return $lastResult
}

function New-TemporaryDirectory 
{
    $tempFolder = [System.IO.Path]::GetTempPath()
    [string] $folderName = [System.Guid]::NewGuid()
	
    return New-Item -ItemType Directory -Path (Join-Path $tempFolder $folderName)
}

function Create-ChildFolder
{
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$ParentFolder,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$ChildFolder,
		
		[Switch]
		$RandomName = $True
    )

    $childFolderFullName = Join-Path $ParentFolder $ChildFolder

	if($RandomName -eq $true)
	{
		$newIdentifyFolder = "{0}-{1}" -f $childFolderFullName,$(Get-Date).ToString("yyMMddhhmmss")
	}
	else
	{
		$newIdentifyFolder = $childFolderFullName
	}
    
	if(-Not (Test-Path $newIdentifyFolder))
	{
		New-Item -Path $newIdentifyFolder -ItemType "directory" | Out-Null
	}
	else
	{
		Write-Error "The folder $newIdentifyFolder already exists"
	}

    return $newIdentifyFolder
}