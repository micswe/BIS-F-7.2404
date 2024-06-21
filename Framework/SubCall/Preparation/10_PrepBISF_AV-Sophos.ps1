﻿<#
	.SYNOPSIS
		Prepare Sophos AntiVirus for Image Managemement
	.DESCRIPTION
	  	Delete computer specific entries
	.EXAMPLE
	.NOTES
		Author: Matthias Schlimm

		History:
	  	09.01.2017 MS: Script created
		20.02.2017 MS: fix typos to get the right servicename -> $ServiceNames[0]
		06.03.2017 MS: Bugfix read Variable $varCLI = ...
		14.08.2019 MS: FRQ 3 - Remove Messagebox and using default setting if GPO is not configured
		03.10.2019 MS: ENH 51 - ADMX Extension: select AnitVirus full scan or custom Scan arguments
		18.02.2020 JK: Fixed Log output spelling

	.LINK
		https://eucweb.com
#>

Begin {
	$script_path = $MyInvocation.MyCommand.Path
	$script_dir = Split-Path -Parent $script_path
	$script_name = [System.IO.Path]::GetFileName($script_path)

	# Product specified
	$Product = "Sophos AntiVirus"
	$Inst_path = "$ProgramFilesx86\Sophos\Sophos Anti-Virus"
	$ServiceNames = @("Sophos Agent", "Sophos AutoUpdate Service", "Sophos Message Router")

	[array]$ToDelete = @(
		[pscustomobject]@{type = "REG"; value = "HKLM:\SOFTWARE\Wow6432Node\Sophos\Messaging System\Router\Private"; data = "pkc" },
		[pscustomobject]@{type = "REG"; value = "HKLM:\SOFTWARE\Wow6432Node\Sophos\Messaging System\Router\Private"; data = "pkp" },
		[pscustomobject]@{type = "REG"; value = "HKLM:\SOFTWARE\Wow6432Node\Sophos\Remote Management System\ManagementAgent\Private"; data = "pkc" },
		[pscustomobject]@{type = "REG"; value = "HKLM:\SOFTWARE\Wow6432Node\Sophos\Remote Management System\ManagementAgent\Private"; data = "pkp" },
		[pscustomobject]@{type = "FILE"; value = "C:\ProgramData\Sophos\AutoUpdate\data"; data = "machine_ID.txt" },
		[pscustomobject]@{type = "FILE"; value = "C:\ProgramData\Sophos\AutoUpdate\data\status"; data = "status.xml" }
	)
}

Process {

	####################################################################
	####### functions #####
	####################################################################

	function RunFullScan {

		Write-BISFLog -Msg "Check GPO Configuration" -SubMsg -Color DarkCyan
		$varCLI = $LIC_BISF_CLI_AV
		IF (($varCLI -eq "YES") -or ($varCLI -eq "NO")) {
			Write-BISFLog -Msg "GPO Valuedata: $varCLI"
		}
		ELSE {
			Write-BISFLog -Msg "GPO not configured.. using default setting" -SubMsg -Color DarkCyan
			$AVScan = "YES"
		}
		if (($AVScan -eq "YES" ) -or ($varCLI -eq "YES")) {
			IF ($LIC_BISF_CLI_AV_VIE_CusScanArgsb -eq 1) {
				Write-BISFLog -Msg "Enable Custom Scan Arguments"
				$args = $LIC_BISF_CLI_AV_VIE_CusScanArgs
			}
			ELSE {
				$args = "-f"
			}

			Write-BISFLog -Msg "Running Scan with arguments: $args"
			Start-Process -FilePath "$Inst_path\sav32cli.exe" -ArgumentList $args
			IF ($OSBitness -eq "32-bit") { $ScanProcess = "sav32cli" } ELSE { $ScanProcess = "sav32cli" }
			Show-BISFProgressBar -CheckProcess "$ScanProcess" -ActivityText "$Product is scanning the system...please wait"
		}
		ELSE {
			Write-BISFLog -Msg "No Scan will be performed"
		}

	}

	function deleteData {
		Write-BISFLog -Msg "Delete specified items "
		Foreach ($2Delete in $ToDelete) {
			IF ($2Delete.type -eq "REG") {
				Write-BISFLog -Msg "Processing Registry-Items to delete" -ShowConsole -SubMsg -color DarkCyan
				$Check2Delete = Test-BISFRegistryValue -Path $2Delete.value -Value $2Delete.data
				IF ($Check2Delete) {
					Write-BISFLog -Msg "Delete RegistryItem -Path($2Delete.value) -Name($2Delete.data)"
					Remove-ItemProperty -Path $2Delete.value -Name $2Delete.data -ErrorAction SilentlyContinue
				}
			}

			IF ($2Delete.type -eq "FILE") {
				Write-BISFLog -Msg "Processing Files to delete" -ShowConsole -SubMsg -color DarkCyan
				$File2Del = "$2Delete.value\$2Delete.data"
				IF (Test-Path ($File2Del) -PathType Leaf) {
					Write-BISFLog -Msg "Delete File $File2Del"
					Remove-Item $File2Del | Out-Null
				}
			}
		}
	}


	function StopService {
		ForEach ($ServiceName in $ServiceNames) {
			$svc = Test-BISFService -ServiceName "$ServiceName"
			IF ($svc -eq $true) { Invoke-BISFService -ServiceName "$($ServiceName)" -Action Stop -StartType manual }
		}
	}

	####################################################################
	####### end functions #####
	####################################################################

	#### Main Program
	$svc = Test-BISFService -ServiceName $ServiceNames[0] -ProductName "$product"
	IF ($svc -eq $true) {
		StopService
		RunFullScan
		deleteData
	}
}

End {
	Add-BISFFinishLine
}