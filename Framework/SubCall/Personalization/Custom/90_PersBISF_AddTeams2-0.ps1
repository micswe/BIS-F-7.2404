<#
    .SYNOPSIS
        Add Teams2.0 from local Disk
	.Description
      	Add Teeams
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
    Author: Michael Schwenke
      	Company: team-netz Consulting

    History
        Last Change: 26.04.2024 MICSWE: Script created

        
    .Link

#>

Begin {
	$Script_Path = $MyInvocation.MyCommand.Path
	$Script_Dir = Split-Path -Parent $Script_Path
	$Script_Name = [System.IO.Path]::GetFileName($Script_Path)


	# Product specIfied
	$product = "Teams2.0"
    $product_file =$env:ProgramFiles + "\MSTeams2.0\MSTeams-x64.msix"
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

        if (($DiskMode -eq "ReadOnly") -or ($DiskMode -eq "ReadOnlyAndSkipImagingAppLayering") -or ($DiskMode -eq "ReadOnlyAppLayering") -or ($DiskMode -eq "VDAShared") -or ($DiskMode -eq "VDASharedAppLayering") -or ($DiskMode -eq "ReadWrite"))
        {
            Write-BISFLog -Msg "vDisk in Standard Mode, Processing $product"
            Add-AppProvisionedPackage -online -packagepath $product_file -skiplicense
        }
        else
        {
            Write-BISFLog -Msg "vDisk in not in Standard Mode ($DiskMode), Skipping $product preparation" -Type W -SubMsg 
        }
	}
}

End {
	Add-BISFFinishLine
}
