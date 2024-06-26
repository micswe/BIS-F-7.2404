<#
    .SYNOPSIS
        Prepare Empirum Agent
	.Description
      	Disable Service
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
    Author: Michael Schwenke
      	Company: team-netz Consulting

    History
		
	.Link
#>

Begin {
	$Script_Path = $MyInvocation.MyCommand.Path
	$Script_Dir = Split-Path -Parent $Script_Path
	$Script_Name = [System.IO.Path]::GetFileName($Script_Path)


	# Product specIfied
	$Product = "Matrix Empirum Agent"
	[array]$reg_service_name =  "Matrix42UAF"
	#[array]$reg_service_name += "..."
	$newStartupType="Disabled"
}

Process {
	####################################################################
	####### Functions #####
	####################################################################
	function Set-ServiceRecovery
    {
        [alias('Set-Recovery')]
        param
        (
            [string] [Parameter(Mandatory=$true)] $ServiceName,
            [string] [Parameter(Mandatory=$true)] $Server,
            [string] $action1 = "restart",
            [int] $time1 =  30000, # in miliseconds
            [string] $action2 = "restart",
            [int] $time2 =  30000, # in miliseconds
            [string] $actionLast = "restart",
            [int] $timeLast = 30000, # in miliseconds
            [int] $resetCounter = 4000 # in seconds
        )
        $serverPath = "\\" + $server
        $action = $action1+"/"+$time1+"/"+$action2+"/"+$time2+"/"+$actionLast+"/"+$timeLast
        
            # https://technet.microsoft.com/en-us/library/cc742019.aspx
        $output = sc.exe $serverPath failure $($ServiceName) actions= $action reset= $resetCounter        
    }

  	####################################################################
	####### End functions #####
	####################################################################

	#### Main Program
	If ((Test-path "C:\Program Files\Matrix42\Universal Agent Framework\Matrix42.Platform.Service.Host.exe") -eq $true) 
	{
		Write-BISFLog -Msg "Product $Product installed" -ShowConsole -Color Cyan

		ForEach ($service_name in $reg_service_name)
		{
			Write-BISFLog -Msg "Change start type for Service: $service_name"
			Set-Service –Name $service_name –StartupType $newStartupType
			#Write-BISFLog -Msg "Service $service_name set Recovery option"
			#Set-ServiceRecovery -ServiceName $service_name -Server "localhost"
		}
	} Else {
		Write-BISFLog -Msg "Product $Product NOT installed"
	}
}


End {
	Add-BISFFinishLine
}
