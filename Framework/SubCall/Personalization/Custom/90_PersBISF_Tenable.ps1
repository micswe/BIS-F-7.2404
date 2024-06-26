<#
    .SYNOPSIS
        Personalize Nessus Tenable Agent
	.Description
      	Delete Computer specIfied entries
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
    Author: Michael Schwenke
      	Company: team-netz Consulting

    History
        Last Change: 16.01.2020 MICSWE: Script created
                     05.03.2020 MICSWE: Change Product detection to Service mode in Main Program
        
    .Link
        https://community.tenable.com/s/article/Create-Windows-or-Linux-image-with-Nessus-Agent-installed

#>

Begin {
	$Script_Path = $MyInvocation.MyCommand.Path
	$Script_Dir = Split-Path -Parent $Script_Path
	$Script_Name = [System.IO.Path]::GetFileName($Script_Path)


	# Product specIfied
	$product = "Nessus Tenable Agent"
    [array]$reg_service_name =  "Tenable Nessus Agent"
    
    $newStartupType="Manual"
    $reg_product_string = "HKLM\Software\Tenable"
    #[array]
    $reg_uid_string= "TAG"

    $cache_tagfile="$PVSDiskDrive\$computer-tenable.txt"

    #Tenable Agent Parameter
    $Global:tenable_host="10.17.162.184"
    $Global:tenable_port="8834"
    $Global:tenable_group=""
    $Global:tenable_key=""
    $Global:tenable_cli="C:\Program Files\Tenable\Nessus Agent\nessuscli.exe"
    
    
    #$Global:tenable_param="agent link --key=$tenable_key --host=$tenable_host --port=$tenable_port --groups=$tenable_group"
}

Process {
	####################################################################
	####### Functions #####
    ####################################################################
    function CheckConfigFiles
    {
        $result = $true
        
        if (!(Test-Path -Path $cache_tagfile -PathType Leaf))
        {
            $result = $false 
        }
        return $result
    }

    Function DeleteComputerID
    {
		ForEach ($service_name in $reg_service_name)
		{
			Write-BISFLog -Msg "Change start type for Service: $service_name"
            Invoke-BISFService -ServiceName $service_name -Action Stop
        }
          
        Write-BISFLog -Msg "Delete specIfied registry items in $reg_product_string..."
        Write-BISFLog -Msg "Delete $reg_uid_string"
        Remove-ItemProperty -Path $reg_product_string -Name $reg_uid_string -ErrorAction SilentlyContinue        
    }

    Function readValues
    {    
        Write-BISFLog -Msg "Processing Nessus Tenable Agent, ReadReg Values"   
        $reg_path="$reg_service_name\Nessus Agent"
        $reg_path.Replace("HKLM","HKLM:")

        $Global:tenable_host=(Get-ItemProperty -Path "$reg_path")."tenable_host"
        $Global:tenable_port=(Get-ItemProperty -Path "$reg_path")."tenable_port"
        $Global:tenable_group=(Get-ItemProperty -Path "$reg_path")."tenable_group"
        $Global:tenable_key=(Get-ItemProperty -Path "$reg_path")."tenable_key"

        $Global:tenable_param="agent link --key=$tenable_key --host=$tenable_host --port=$tenable_port --groups=$tenable_group"
    }

  	####################################################################
	####### End functions #####
	####################################################################

    #### Main Program
    #If ((Test-path "Registry::$reg_product_string") -eq $true) 
    $svc = Test-BISFService -ServiceName "$reg_service_name" -ProductName "$product"

    If ($svc -eq $true) 
	{
		#Write-BISFLog -Msg "Product $product installed" -ShowConsole -Color Cyan
        $DiskMode = Get-BISFDiskMode
        
        readValues

        if (($DiskMode -eq "ReadOnly") -or ($DiskMode -eq "VDAShared") -or ($DiskMode -eq "ReadWrite"))
        {
            Write-BISFLog -Msg "vDisk in Standard Mode, Processing Nessus Tenable Agent"   
            if (!(CheckConfigFiles)) 
            {
                Write-BISFLog -Msg "Nessus Tenable Agent Config File not valid $cache_tagfile" -Type W  -SubMsg 
               
                ForEach ($service_name in $reg_service_name)
   		        {
                    Try
                    {
		        	    If ((Get-Service $service_name -ErrorAction Stop).StartType -eq "Disabled")
			            {
                            Write-BISFLog -Msg "Service $service_name is Disabled, set to Autostart and start the Service"
                            Set-Service –Name $service_name –StartupType $newStartupType	                    
                        }
                        Write-BISFLog -Msg "Service $service_name is starting ..."
                        Start-Service –Name $service_name     
                    }
                    Catch
                    {      
                        Write-BISFLog -Msg "Error on change Service $service_name."
                    }
                }


                ###Prüfung ob ID vorhanden####
                $tag = (Get-ItemProperty -Path Registry::$reg_product_string -Name $reg_uid_string -ErrorAction SilentlyContinue).tag

                if ($tag)
                {
                    Write-BISFLog -Msg "UUID found in registry."
                }
                else
                {
                    #Register Agent
                    Write-BISFLog -Msg "Register Agent"
                    & $tenable_cli $Global:tenable_param.split(" ") | Tee-Object -Variable tenable_result | Out-Null

				    Write-BISFLog -Msg "Result register Agent: \n\n $tenable_result"
               
				    # Wait 3 Minutes before UUID Backup
                    Sleep -Seconds 180               
                }
            
                Write-BISFLog -Msg "Backup UUID from registry to $cache_tagfile"
                $tag = (Get-ItemProperty -Path Registry::$reg_product_string -Name $reg_uid_string -ErrorAction SilentlyContinue).tag     
                
                Write-BISFLog -Msg "Backup UUID $tag to $cache_tagfile"
                Set-Content -Path $cache_tagfile -Value $tag
            }
            else
            {
                Write-BISFLog -Msg "Valid UUID File Found in  $cache_tagfile, Restoring"

                $tag=Get-Content -Path $cache_tagfile | Out-String

                Write-BISFLog -Msg "Valid UUID $tag, Restoring"                
                Set-ItemProperty -Path Registry::$reg_product_string -Name $reg_uid_string -value $tag -ErrorAction SilentlyContinue

                ForEach ($service_name in $reg_service_name)
                {
                    Try
                    {
                        If ((Get-Service $service_name -ErrorAction Stop).StartType -eq "Disabled")
                        {
                            Write-BISFLog -Msg "Service $service_name is Disabled, set to Autostart and start the Service"
                            Set-Service –Name $service_name –StartupType $newStartupType	                    
                        }
                        Write-BISFLog -Msg "Service $service_name is starting ..."
                        Start-Service –Name $service_name     
                    }
                    Catch
                    {      
                        Write-BISFLog -Msg "Error on change Service $service_name."
                    }
                }    
            }
        }
        else
        {
            Write-BISFLog -Msg "vDisk in not in Standard Mode ($DiskMode), Skipping Nessus Tenable Agent preparation" -Type W -SubMsg 
        }
	}
}

End {
	Add-BISFFinishLine
}
