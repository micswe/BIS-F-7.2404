<#
    .SYNOPSIS
        Windows KMS Check script
	.Description
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
    	Author: Michael Schwenke
      	Company: team-netz Consulting

		History
        Last Change: 07.07.2020 Create Script

	.Link
#>

<No installed product keys detected>

Begin {
    $script_path = $MyInvocation.MyCommand.Path
	$script_dir = Split-Path -Parent $script_path
	$script_name = [System.IO.Path]::GetFileName($script_path)

    $filePath="C:\Personality.ini"

	# Product specIfied
	$Product = "Check Windows KMS"
	$VerifyLicensed_EN= "License Status: Licensed"
	$VerifyLicensed_DE= "Lizenzstatus: Lizenziert"
}

Process
{
	####################################################################
	####### Functions #####
	####################################################################
	function Get-IniContent ($filePath)
	{
		$ini = @{ }
		switch -regex -file $FilePath
		{
			"^\[(.+)\]" # Section
			{
				$section = $matches[1]
				$ini[$section] = @{ }
				$CommentCount = 0
			}
			"^(;.*)$" # Comment
			{
				$value = $matches[1]
				$CommentCount = $CommentCount + 1
				$name = "Comment" + $CommentCount
				$ini[$section][$name] = $value
			}
			"(.+?)\s*=(.*)" # Key
			{
				$name, $value = $matches[1 .. 2]
				$ini[$section][$name] = $value
			}
		}
		return $ini
	}
		
	function Check-WindowsKMS
	{
		[alias('Check-WindowsKMS')]
		$output = C:\Windows\System32\cscript.exe  C:\Windows\System32\slmgr.vbs /dlv

		if ($output -contains $VerifyLicensed_DE -or $output -contains $VerifyLicensed_EN)
		{
			return $true
		}
		else
		{
			return $false
		}	
        
        return $false
	}
	
	####################################################################
	####### End functions #####
	####################################################################
	
	#### Main Program
	Write-BISFLog -Msg "Product $Product execute" -ShowConsole -Color Cyan
	
	$Global:Personality = @{ }
	
	If (Test-Path ("$filePath") -PathType Leaf)
	{
		$Personality = Get-IniContent $filePath
		
		if ("S" -eq $Personality['ArdenceData']['_DiskMode'].ToString())
		{
		    Write-BISFLog -Msg "PVS vDisk is in Private mode." -ShowConsole -Color Cyan
		
	
	        if (Check-WindowsKMS)
	        {
		        Write-BISFLog -Msg "Windows activated, nothing to do." -ShowConsole -Color Cyan
	        }
	        else
	        {
		        Write-BISFLog -Msg "Windows not activated, run cscript slmgr.vbs /ato" -ShowConsole -Color Cyan
		        		
		        $output = C:\Windows\System32\cscript.exe  C:\Windows\System32\slmgr.vbs /ato
		
        		Write-BISFLog -Msg "$output" -ShowConsole -Color Cyan
        	}
	
	    }
	}
}
End {
	Add-BISFFinishLine
}
