<#
    .SYNOPSIS
        Personalize MediDok
	.Description
      	Delete Computer specIfied entries
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
    Author: Michael Schwenke
      	Company: team-netz Consulting

    History
        Last Change: 27.10.2021 MICSWE: Script created

        
    .Link

#>

Begin {
	$Script_Path = $MyInvocation.MyCommand.Path
	$Script_Dir = Split-Path -Parent $Script_Path
	$Script_Name = [System.IO.Path]::GetFileName($Script_Path)


	# Product specIfied
	$product = "MediDok"
    $product_file ="C:\medidok25\mediDOK.exe"
  
    $cache_configfile="$PVSDiskDrive\MediDok\ConnectionSettings.xml"
}

Process {
	####################################################################
	####### Functions #####
    ####################################################################
    function CheckConfigFiles
    {
        $result = $true
        
        if (!(Test-Path -Path $cache_configfile -PathType Leaf))
        {
            $result = $false 
        }
        return $result
    }

    function CheckProgramExists    {
        PARAM(
	    	[parameter(Mandatory = $True)][string]$ProductName
    	)   
    	
	    write-BISFlog -Msg "Check $ProductName"
    
        $result = $true
        
        if (!(Test-Path -Path $product_file -PathType Leaf))
        {
            $result = $false 
        }
        return $result
    }

  	####################################################################
	####### End functions #####
	####################################################################

    #### Main Program

    $svc = CheckProgramExists -ProductName "$product"

    If ($svc -eq $true) 
	{
        $DiskMode = Get-BISFDiskMode
        
        ##readValues

        if (($DiskMode -eq "ReadOnly") -or ($DiskMode -eq "ReadOnlyAndSkipImagingAppLayering") -or ($DiskMode -eq "VDAShared") -or ($DiskMode -eq "ReadWrite"))
        {
            Write-BISFLog -Msg "vDisk in Standard Mode, Processing MediDok"   
            if (!(CheckConfigFiles)) 
            {
                Write-BISFLog -Msg "MediDok Config File not valid $cache_configfile" -Type W  -SubMsg 
            }
            else
            {
                Write-BISFLog -Msg "Valid MediDok File Found $cache_configfile, Restoring"
                Write-BISFLog -Msg "Valid MediDok, Restoring"                
                Copy-Item $cache_configfile -Destination "C:\ProgramData\mediDOK" -Force
            }
        }
        else
        {
            Write-BISFLog -Msg "vDisk in not in Standard Mode ($DiskMode), Skipping MediDok preparation" -Type W -SubMsg 
        }
	}
}

End {
	Add-BISFFinishLine
}
