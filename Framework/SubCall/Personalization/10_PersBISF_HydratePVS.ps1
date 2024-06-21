<#
    .Synopsis
      Enables pre-caching of files for PVS systems
    .Description
      Enables pre-caching of files for PVS systems
      Tested on Server 2019
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES

      History
		  2019.08.16 TT: Script created
		  18.08.2019 MS: integrate into BIS-F
		  03.02.2020 MS: HF 201 - Hydration not startig if configured
		  23.05.2020 MS: HF 231 - Skipping file precache if vDisk is in private Mode
		  **
  		  20.04.2020 Micswe: Add Work Hours, Skip Hydrate on boot in WorkHourse
		  19.09.2020 Micswe: Add Exclude FolderPath

	  .Link
		  https://github.com/EUCweb/BIS-F/issues/129

	  .Link
		  https://eucweb.com
    #>

	Begin {
		$script_path = $MyInvocation.MyCommand.Path
		$script_dir = Split-Path -Parent $script_path
		$script_name = [System.IO.Path]::GetFileName($script_path)
		$PathsToCache = $LIC_BISF_CLI_PVSHydration_Paths
		$ExtensionsToCache = $LIC_BISF_CLI_PVSHydration_Extensions
		$PathsToExclude = $LIC_BISF_CLI_PVSHydration_ExcludePaths
		[int]$only_runfrom=23
		[int]$only_runto=5
		[bool]$check_Work_Hour=$true
	}
	
	Process {
	
		####################################################################
		####### Functions #####
		####################################################################
		function FileToCache ($File) {
			#Write-BISFLog -Msg "Caching File : $File" -ShowConsole -Color Cyan
			$hydratedFile = [System.IO.File]::ReadAllBytes($File)
		}
	
  		####################################################################
		####### End functions #####
		####################################################################

		#check time
		[int]$time_hour=(Get-Date -Format HH)

		if (($time_hour -ge $only_runfrom -or $time_hour -le $only_runto) -or $check_Work_Hour -eq $false)
		{

			$WriteCacheType = Get-BISFPVSWriteCacheType
			if ($WriteCacheType -eq 0) {   # private Mode
				Write-BISFLog -Msg "PVS vDisk is in Private Mode. Skipping file precache."  -ShowConsole -Color Yellow
				Return
			}
	
			if (-not(Test-BISFPVSSoftware)) {
				Write-BISFLog -Msg "PVS Software not found. Skipping file precache."  -ShowConsole -Color Yellow
				Return
			}
			if (-not($LIC_BISF_CLI_PVSHydration -eq "YES")) {
				Write-BISFLog -Msg "File precache configuration not found. Skipping."  -ShowConsole -Color Yellow
				Return
			}
	
			#foreach ($Path in ($PathsToCache.split("|"))) {
			#Write-BISFLog -Msg "Caching files with extensions $ExtensionsToCache in $Path" -ShowConsole -Color Cyan
			#	foreach ($File in (Get-ChildItem -Path $Path -Recurse -File -Include $ExtensionsToCache.Split(","))) {
			#		FileToCache -File $File
			#	}
			#}

			foreach ($Path in ($PathsToCache.split("|"))) { 
				Write-BISFLog -Msg "Caching files with extensions $ExtensionsToCache in $Path" -ShowConsole -Color Cyan
				$noDirRegex='^{0}' -f ($PathsToExclude.Replace("\","\\").Replace("(","\(").Replace(")","\)").Split("|") -join ('|^'))            
				Write-BISFLog -Msg "RegEx: $noDirRegex" -ShowConsole -Color Yellow
	
				foreach ($File in (Get-ChildItem -Path $Path -Recurse -File -Include $ExtensionsToCache.Split(","))) 
				{ 
					if ($File.DirectoryName -inotmatch $noDirRegex) 
					{ 
						   FileToCache -File $File
					} 
				}                     
			}
		}
		else
		{
			Write-BISFLog -Msg "Skype Hydrate, Start in Work hours."  -ShowConsole -Color Yellow
		}
	}
	
	End {
		Add-BISFFinishLine
	}