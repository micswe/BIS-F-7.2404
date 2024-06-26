<#
    .SYNOPSIS
        Master Mode for PVS Master Image Update
	.Description
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
    	Author: Michael Schwenke
      	Company: team-netz Consulting

		History
        Last Change: 06.07.2020 Chage Service Recovery option

	.Link
#>

Begin {
    $script_path = $MyInvocation.MyCommand.Path
	$script_dir = Split-Path -Parent $script_path
	$script_name = [System.IO.Path]::GetFileName($script_path)

    $filePath="C:\Personality.ini"

	# Product specIfied
	$Product = "Master Mode"
	[array]$reg_service_name =  "Matrix42UAF"
	#[array]$reg_service_name += "ersupext"
	#[array]$reg_service_name += "wuauserv"
    
    # Change Recoveryoption
    [array]$reg_service_name_recovery =  "Matrix42UAF"

	# StartupType are: Automatic, Manual or Disabled
	$newStartupType="Automatic"
}

Process {
	####################################################################
	####### Functions #####
	####################################################################
    function Get-IniContent ($filePath)
    {
        $ini = @{}
        switch -regex -file $FilePath
        {
            “^\[(.+)\]” # Section
            {
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
            }
            “^(;.*)$” # Comment
            {
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = “Comment” + $CommentCount
                $ini[$section][$name] = $value
            }
            “(.+?)\s*=(.*)” # Key
            {
                $name,$value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
        return $ini
    }
    
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
	Write-BISFLog -Msg "Product $Product execute" -ShowConsole -Color Cyan
	
	$Global:Personality=@{}

    If (Test-Path ("$filePath") -PathType Leaf)
    {
		$Personality=Get-IniContent $filePath

        if ("P" -eq $Personality['CitrixData']['_DiskMode'].ToString())
        {
            Write-BISFLog -Msg "PVS vDisk is in Private mode." -ShowConsole -Color Cyan
            
	        ForEach ($service_name in $reg_service_name)
   		    {
                Try
                {
		        	If ((Get-Service $service_name -ErrorAction Stop).StartType -eq "Disabled")
			        {
                        Write-BISFLog -Msg "Service $service_name is Disabled, set to Autostart and start the Service"
                        Set-Service –Name $service_name –StartupType $newStartupType	                    
                        Start-Service –Name $service_name                     
	    		    }
                }
                Catch
                {
                    Write-BISFLog -Msg "Error on change Service $service_name."
                }
            }

            #Set Recover Option       
            #ForEach ($service_name in $reg_service_name_recovery)
            #{
            # Try
            # {
            #    Write-BISFLog -Msg "Service $service_name set Recovery option"
            #    Set-ServiceRecovery -ServiceName $service_name -Server "localhost"
            # }
            # Catch
            # {
            #     Write-BISFLog -Msg "Error on change Service $service_name recovery mode."
            # }
            #}
        }
        Else {
            Write-BISFLog -Msg "PVS vDisk is in Standard mode."
        } 
    }
}

End {
	Add-BISFFinishLine
}
