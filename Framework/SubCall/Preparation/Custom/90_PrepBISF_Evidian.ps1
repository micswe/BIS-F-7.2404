<#
    .SYNOPSIS
        Prepare Evidian Agent for Image Managemement
	.Description
      	Delete Computer specIfied entries
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

	# Product specIfied
	$Product = "Enterprise Access Management"
	$reg_product_string = "HKLM:\SOFTWARE\Enatel\WiseGuard\Framework\AccessPoint\"
	$Product_Path = "$ProgramFiles\Evidian\Enterprise Access Management"
	$ServiceName1 = "EvidianWGSS"
	$ServiceName2 = "EvidianSENS"
	[array]$reg_product_name = "ComputerID"
 	
}

Process {
####################################################################
####### Functions #####
####################################################################


  Function DeleteComputerID
  {
		Invoke-BISFService -ServiceName "$ServiceName1" -Action Stop
		Invoke-BISFService -ServiceName "$ServiceName2" -Action Stop

		ForEach ($key in $reg_product_name)
		{
			Write-BISFLog -Msg "Delete specIfied registry items in $reg_product_string..."
			Write-BISFLog -Msg "Delete $key"
			Remove-ItemProperty -Path $reg_product_string -Name $key -ErrorAction SilentlyContinue
		}
  }

  Function DeleteCacheFiles
  {
		Write-BISFLog -Msg "Delete Files"
		Get-ChildItem -Path "C:\Program Files\Common Files\Evidian\WGSS\CacheDir" -Include * -File -Recurse | ForEach-Object { $_.Delete()}
  }

	####################################################################
	####### End functions #####
	####################################################################

	#### Main Program
	# umbau auf Service

#	$svc = Test-BISFService -ServiceName "$servicename" -ProductName "$product"
#	IF ($svc -eq $true) {
#		Invoke-BISFService -ServiceName "$servicename" -Action Stop
#		ClearConfig
#		Set-RulesShare
#	}

    If (Test-Path ("$Product_Path\SSOLauncher.exe") -PathType Leaf)

	{
        Write-BISFLog -Msg "Product $Product installed" -ShowConsole -Color Cyan
        DeleteComputerID
		DeleteCacheFiles
	} Else {
		Write-BISFLog -Msg "Product $Product NOT installed"
	}
}


End {
	Add-BISFFinishLine
}
