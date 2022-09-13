<#
.Synopsis
   To run as preparation to update Personec P
.DESCRIPTION
   With the script you will extract data from web.config to be verified before update.
   Backup of programs and wwwroot
   Get data about services status before update
   Get info about .net 4.8
.EXAMPLE
   InstallSupport-PersonecP.ps1 -backup
   Runs backup of folders 
.EXAMPLE
   InstallSupport-PersonecP.ps1 -InventorySystem
.EXAMPLE
   InstallSupport-PersonecP.ps1 -InventoryConfig
.EXAMPLE
   InstallSupport-PersonecP.ps1 -ShutdownServices
.EXAMPLE
   Set-BGInfo.ps1 -CopyReports
.NOTES
   Filename: Pre-InstallPersonec_P.ps1
   Author: Christian Damberg
   Website: https://www.damberg.org
   Email: christian@damberg.org
   Modified date: 2022-05-12
   Version 1.0 - First release
   Version 1.1 - Updated step inventory to extract appool settings
   
#>

#------------------------------------------------#
# Parameters

    Param(
    [Parameter(Mandatory=$false)]
    [Switch]$Backup,
    [Parameter(Mandatory=$false)]
    [Switch]$InventoryConfig,
    [Parameter(Mandatory=$false)]
    [Switch]$InventorySystem,
    [Parameter(Mandatory=$false)]
    [Switch]$ShutdownServices,
    [Parameter(Mandatory=$false)]
    [Switch]$CopyReports,
    [Parameter(Mandatory=$false)]
    [Switch]$FlyttaMallar,
    [Parameter(Mandatory=$false)]
    [Switch]$SqlQuery,
    [Parameter(Mandatory=$false)]
    [Switch]$SqlUsers
    )


#------------------------------------------------#
# Variables & arrays

    #$bigram = read-host 'Bigram?'
    $bigram = 'VISMA'
    
    # Todays date (used with backupfolder and Pre-Check txt file
    $Today = (get-date -Format yyyyMMdd)

    $time = (get-date -Format HH:MM:ss)
    
    # Services to check
    $services = "Ciceron Server Manager","PersonecPBatchManager","Personec P utdata export Import Service","RSPFlexService","W3SVC","World Wide Web Publishing Service"
    
    # Array to save data
    $data = @()

    $logfile = "$PSScriptRoot\$today\Pre-InstallPersonec_P_$today.log"

    #Long DB Version
    $long_db_version = 22040

    #Short DB Version
    $short_db_version = 2240

    #DB script path (Parent directory where you find "Install/HRM")
    $db_script_path = "D:\Visma"
#------------------------------------------------#
# Functions in script
   
    # Function to write to logfile
    Function Write-Log {
      [CmdletBinding()]
      Param(
      [Parameter(Mandatory=$False)]
      [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
      [String]
      $Level = "INFO",
    
      [Parameter(Mandatory=$True)]
      [string]
      $Message
      )
    
      $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
      $Line = "$Stamp $Level $Message"
      "$Stamp $Level $Message" | Out-File -Encoding utf8 $logfile -Append
      }


      function Get-IniFile 
{  
    param(  
        [parameter(Mandatory = $true)] [string] $filePath  
    )  
    
    $anonymous = "NoSection"
  
    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  

        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   

        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $ini[$section][$name] = $value  
        }  
    }  

    return $ini  
} 
      #write-log -Level INFO -Message "Running script"
#------------------------------------------------#
# Service and web.config

$folder = (test-path -Path "D:\visma\Install\Backup\$Today\")

if ($folder -eq $false)
{
    New-Item -Path "d:\visma\install\backup\" -ItemType Directory  -Name $Today
}


if ($InventorySystem -eq $true)
{
   # Check and document services
    foreach ($Service in $Services)
    {
        $InfoOnService = Get-WmiObject Win32_Service | where Name -eq $Service | Select-Object name,startname,state,Startmode -ErrorAction SilentlyContinue
        #Write-Log -Level INFO -Message "Checking status for $service "
        $data += $InfoOnService
    }
    
    # Send data to file about services
    $time | Out-File "$PSScriptRoot\$today\Services_$Today.txt" -Append
    $data | Out-File "$PSScriptRoot\$today\Services_$Today.txt" -Append
    
    # Check dotnet version installed and send to file
    $dotnet = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where { $_.PSChildName -Match '^(?!S)\p{L}'} | Select PSChildName, version | Sort-Object version -Descending | Out-File $PSScriptRoot\$today\DotNet_$today.txt -Append
   
   # get installed software

   $installed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction Ignore | Where-Object publisher -eq 'Visma' | Select-Object -Property DisplayName, DisplayVersion, Publisher | Sort-Object -Property DisplayName
   $time | Out-File "$PSScriptRoot\$today\InstalledSoftware_$Today.txt" -Append
   $installed | Out-File "$PSScriptRoot\$today\InstalledSoftware_$Today.txt" -Append


}

if ($InventoryConfig -eq $true)
{

    ########################################
    # UserSSo check
    $UseSSOBackup = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$bigram\$bigram\Login\Web.config")

    if ($UseSSOBackup -eq $true)

        {
        [XML]$UseSSO = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\$bigram\Login\Web.config" -ErrorAction SilentlyContinue
        $time | Out-File "$PSScriptRoot\$today\UseSSO_Check_$Today.txt" -Append
        $UseSSO.configuration.appSettings.add | out-file "$PSScriptRoot\$today\UseSSO_Check_$Today.txt" -Append
        }
    Else
        {
         write-host "No web.config for UseSSO in backup"
        }


 ########################################
    # förhandling check
    $forhandling = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$bigram\pfh\services\Web.config")

    if ($forhandling -eq $true)

        {
        [XML]$forhandlingsettings = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\pfh\services\Web.config" -ErrorAction SilentlyContinue
        $time | Out-File "$PSScriptRoot\$today\forhandling_$Today.txt" -Append
        $forhandlingsettings.configuration.appSettings.add | out-file "$PSScriptRoot\$today\forhandling_$Today.txt" -Append
        }
    Else
        {
         write-host "No web.config for forhandling in backup"
        }

    ######################################
    # Befolkning

    $befolkningBackup = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$bigram\PPP\Personec_P_web\Lon\web.config")

    if ($befolkningBackup -eq $true)

        {
        [XML]$UseBEfolk = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\PPP\Personec_P_web\Lon\web.config" -ErrorAction SilentlyContinue
        $time | Out-File "$PSScriptRoot\$today\Befolk_Check_$Today.txt" -Append
        $UseBEfolk.configuration.appSettings.add | out-file "$PSScriptRoot\$today\Befolk_Check_$Today.txt" -Append
        }
    else
        {
         write-host "No web.config for befolkning in backup"
        }

    #######################################
    # PStid.ini

    $pathPStid = (Test-Path "$PSScriptRoot\$today\programs\$bigram\ppp\Personec_p\pstid.ini")
    
    if ($pathPStid -eq $true)

        {
        $pstid = Get-IniFile "$PSScriptRoot\$today\programs\$bigram\ppp\Personec_p\pstid.ini"
        $NeptuneUser = $PSTID.styr.NeptuneUser
        $NeptunePwd = $PSTID.styr.neptunepassword
        
        $NeptuneData = @{
        'NeptuneUser' = $NeptuneUser
        'NeptunePwd' = $NeptunePwd
                    }
     
        $NeptuneData | out-file "$PSScriptRoot\$today\Neptune_$Today.txt"
        $NeptuneData | Out-File "$PSScriptRoot\$today\Personec_P.txt"
        }
   else
        {
        write-host "No PSTID"
        }

    ########################################
    # Egna rapporter check

    $ReportsBackupPPP = (Test-Path "$PSScriptRoot\$Today\Wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt")

    if ($ReportsBackupPPP -eq $true)
        {
        $rapport = Get-ChildItem -Recurse "$PSScriptRoot\$Today\Wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt"
        $time | Out-File "$PSScriptRoot\$today\ReportsPPP_$Today.txt" -Append
        $rapport | out-file "$PSScriptRoot\$today\reportsPPP_$Today.txt" -Append
        }
else 
        {
         write-host "No reports for PPP in backup"
        }

      $ReportsBackupAG = (Test-Path "$PSScriptRoot\$Today\Wwwroot\$bigram\PPP\Personec_AG\CR\rpt")

    if ($ReportsBackupAG -eq $true)
        {
        $rapport = Get-ChildItem -Recurse "$PSScriptRoot\$Today\Wwwroot\$bigram\PPP\Personec_AG\CR\rpt"
        $time | Out-File "$PSScriptRoot\$today\ReportsAG_$Today.txt" -Append
        $rapport | out-file "$PSScriptRoot\$today\reportsAG_$Today.txt" -Append
        }
else 
        {
         write-host "No reports for AG in backup"
        }        
    #########################################
    # Batch check
    $BatchBackup = (Test-Path "$PSScriptRoot\$today\Programs\$bigram\PPP\Personec_P\batch.config")

    if ($BatchBackup -eq $true)
        {
        [xml]$Batch = Get-Content "$PSScriptRoot\$today\Programs\$bigram\PPP\Personec_P\batch.config" -ErrorAction SilentlyContinue 


        $batchuser = $Batch.configuration.appSettings.add |Where-Object {$_.key -eq 'sysuser'} | Select-Object value
        $batchpwd = $batch.configuration.appSettings.add |Where-Object {$_.key -eq 'SysPassword'} | Select-Object value

        $batchData = @{
        'BatchPassword' = $batchpwd.value
        'Batchuser' = $batchuser.value
        
        }

        $batchData | Out-File "$PSScriptRoot\$today\Batch_$Today.txt"
        $batchData | Out-File "$PSScriptRoot\$today\Personec_P.txt" -Append
        
        }
    Else
        {
        write-host "No batch"
        }

    #########################################
    # PIA Webconfig check
      $PiaBackup = (Test-Path "$PSScriptRoot\$today\wwwroot\$bigram\PIA\PUF_IA Module\web.config")

    if ($PiaBackup -eq $true)
        {
        [XML]$PIA = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\PIA\PUF_IA Module\web.config" -ErrorAction SilentlyContinue

        $PIA_PPP_USER = $pia.configuration.appSettings.add |Where-Object {$_.key -eq 'P.Database.User'} | Select-Object value
        $PIA_PPP_PWD = $pia.configuration.appSettings.add |Where-Object {$_.key -eq 'P.Database.Password'} | Select-Object value
        $PIA_PUD_USER = $pia.configuration.appSettings.add |Where-Object {$_.key -eq 'U.Database.User'} | Select-Object value
        $PIA_PUD_PWD = $pia.configuration.appSettings.add |Where-Object {$_.key -eq 'U.Database.Password'} | Select-Object value
        $PIA_SRV_USER = $pia.configuration.appSettings.add |Where-Object {$_.key -eq 'ServiceUser.Login'} | Select-Object value
        $PIA_SRV_PWD = $pia.configuration.appSettings.add |Where-Object {$_.key -eq 'ServiceUser.secret'} | Select-Object value
        
        $PIADATA = @{
        'PPP' = $PIA_PPP_USER.value,$PIA_PPP_PWD.value
        'PUD' = $PIA_PUD_USER.value,$PIA_PUD_PWD.value
        'PFH' = $PIA_PFH_USER.value,$PIA_PFH_PWD.value
        'Service' = $PIA_SRV_USER.value,$PIA_SRV_PWD.value
                    }
        $PIADATA | out-file "$PSScriptRoot\$today\PIA_$Today.txt"
        }
    Else
        {
        WRITE-HOST "No web.config for PIA in backup"
        }
   
   ####################################################################
    # AppPool check

    try 
        {
        $appPools = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add'
        $appPoolResultat = [System.Collections.ArrayList]::new()
        
        foreach($appPool in $appPools)
        {
            if($appPool.ProcessModel.identityType -eq "SpecificUser")
                {
                #Write-Host $appPool.Name -ForegroundColor Green -NoNewline
                #Write-Host " -"$appPool.ProcessModel.UserName"="$appPool.ProcessModel.Password
                #Write-Host " -"$appPool.ProcessModel.UserName

                [void]$appPoolResultat.add([PSCustomObject]@{
                Name = $appPool.name
                User = $appPool.ProcessModel.UserName
                #Password = $appPool.ProcessModel.Password
                })
                }
        }
        $time | Out-File "$PSScriptRoot\$today\ApplicationPoolIdentity_$Today.txt" -Append
        $appPoolResultat |out-file "$PSScriptRoot\$today\ApplicationPoolIdentity_$Today.txt" -Append
    }

    catch 
        {
        write-host "no app-pool"
        }

    #################################    
    
    }
    

#------------------------------------------------#
# Backup of folders

# Copy to backup
if ($Backup -eq $true)
    {
        robocopy D:\Visma\Wwwroot\ D:\Visma\Install\backup\$Today\wwwroot\ /e /xf *.log, *.svclog
        robocopy D:\Visma\Programs\ D:\Visma\Install\backup\$Today\programs\ /e /xf *.log
    }


#------------------------------------------------#
# Stop services

if ($ShutdownServices -eq $true)
    {
        # Stop WWW site Bigram
        Stop-IISSite -Name $bigram -Verbose -Confirm:$false
        #Write-Log -Level INFO -Message "Stopped website for $bigram"

        foreach ($Service in $Services)
        {
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue -Verbose
            #Write-Log -Level INFO -Message "Stopped $service if it was running"
            
        }
        
    }

#------------------------------------------------#
<# Copy customermade reports
if ($CopyReports -eq $true)
    {
# Personec P web
    $Folder1path = "$PSScriptRoot\$Today\Wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt"
    $Folder2path = "D:\Visma\Wwwroot\VISMA\ppp\Personec_P_web\Lon\cr\rpt"
 
$ErrorActionPreference = "Stop";
Set-StrictMode -Version 'Latest'

Get-ChildItem -Path $Folder1Path -Recurse | Where-Object {

    [string] $toDiff = $_.FullName.Replace($Folder1path, $Folder2path)
    # Determine what's in 2, but not 1
    [bool] $isDiff = (Test-Path -Path $toDiff) -eq $false
    
    if ($isDiff) {
        # Create destination path that contains folder structure
        $dest = $_.FullName.Replace($Folder1path, $Folder2path)
        Copy-Item -Path $_.FullName -Destination $dest -Verbose -Force
        #write-log -Level INFO -Message "Copy $_. to $dest"
    }
}

# Personec AG
    $Folder1path = "$PSScriptRoot\$Today\Wwwroot\$bigram\PPP\Personec_AG\CR\rpt"
    $Folder2path = "D:\Visma\Wwwroot\VISMA\PPP\Personec_AG\CR\rpt"
 
$ErrorActionPreference = "Stop";
Set-StrictMode -Version 'Latest'

Get-ChildItem -Path $Folder1Path -Recurse | Where-Object {

    [string] $toDiff = $_.FullName.Replace($Folder1path, $Folder2path)
    # Determine what's in 2, but not 1
    [bool] $isDiff = (Test-Path -Path $toDiff) -eq $false
    
    if ($isDiff) {
        # Create destination path that contains folder structure
        $dest = $_.FullName.Replace($Folder1path, $Folder2path)
        Copy-Item -Path $_.FullName -Destination $dest -Verbose -Force
        #write-log -Level INFO -Message "Copy $_. to $dest"
    }
}
}
#>
#------------------------------------------------#
# Move Template folders
if ($FlyttaMallar -eq $true)
    {
        Remove-Item -Path "D:\Visma\wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt\*"
        Remove-Item -Path "D:\Visma\wwwroot\$bigram\PPP\Personec_AG\CR\rpt\*"
        Write-Output("Robocopy D:\Visma\Install\Backup\$Today\wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt D:\Visma\wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt")
        Write-Output("Robocopy D:\Visma\Install\Backup\$Today\wwwroot\$bigram\PPP\Personec_AG\CR\rpt D:\Visma\wwwroot\$bigram\PPP\Personec_AG\CR\rpt")
    }


#------------------------------------------------#
# Get Sql Query
if ($SqlQuery -eq $true)
    {
        $query = "##Personic P" +    
        "`rUSE $bigram" + "_PPP" +
        "`rSELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997" + 
        "`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\mRSPu$short_db_version.sql" +
            
        "`n`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\mRSPview.sql" +
        "`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\mRSPproc.sql" +
        "`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\mRSPtriggers.sql" +
        "`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\mRSPgra.sql" +
        "`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\msDBUPDATERIGHTSP.sql" +
        "`r:r  $db_script_path\Install\HRM\PPP\DatabaseServer\Script\SW\$long_db_version\PPPds_Feltexter.sql" +
            
        "`n`rSELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997" +
        "`rSELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc" +
        "`r#------------------------------------------------#" +
        "`n`r#Personic U" +
        "`rUSE $bigram" + "_PUD" +
        "`rSELECT * FROM dbo.PU_VERSIONSINFO" +
        "`r:r  $db_script_path\Install\HRM\PUD\DatabaseServer\Script\SW\$long_db_version\mPSUu$short_db_version.sql" +
            
        "`n`r:r  $db_script_path\Install\HRM\PUD\DatabaseServer\Script\SW\$long_db_version\mPSUproc.sql" +
        "`r:r  $db_script_path\Install\HRM\PUD\DatabaseServer\Script\SW\$long_db_version\mPSUview.sql" +
        "`r:r  $db_script_path\Install\HRM\PUD\DatabaseServer\Script\SW\$long_db_version\mPSUgra.sql" +
        "`r:r  $db_script_path\Install\HRM\PUD\DatabaseServer\Script\SW\$long_db_version\msdbupdaterightsU.sql" +
            
        "`n`rSELECT * FROM dbo.PU_VERSIONSINFO" +
        "`rSELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc" +
        "`r#------------------------------------------------#" +
        "`n`r##Personic PFH" +
            
        "`rUSE $bigram" + "_PFH" +
        "`rSELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997" +
        "`r:r $db_script_path\Install\HRM\PFH\DatabaseServer\Script\SW\$long_db_version\mPSFu$short_db_version.sql" +
            
        "`n`r:r $db_script_path\Install\HRM\PFH\DatabaseServer\Script\SW\$long_db_version\mPSFproc.sql" +
        "`r:r $db_script_path\Install\HRM\PFH\DatabaseServer\Script\SW\$long_db_version\mPSFview.sql" +
        "`r:r $db_script_path\Install\HRM\PFH\DatabaseServer\Script\SW\$long_db_version\mPSFgra.sql" +
        "`r:r $db_script_path\Install\HRM\PFH\DatabaseServer\Script\SW\$long_db_version\msDBUPDATERIGHTSF.sql" +
        "`r:r $db_script_path\Install\HRM\PFH\DatabaseServer\Script\SW\$long_db_version\PFHds_Feltexter.sql" +
        
        "`rSELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997" +
        "`n`rSELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc"
            
        Out-File -FilePath $PSScriptRoot\SqlQuery.txt -Encoding Unicode -InputObject $query
    }
        
#------------------------------------------------#
#SQL Query for importing accounts
if ($SqlUsers -eq $true)
    {
        $sql_users = "##Personic P" +
        "sp_change_users_login report" +
        "sp_change_users_login update_one,rspdbuser,rspdbuser" +
        "sp_change_users_login update_one,psutotint,psutotint" +
        "sp_change_users_login update_one,eko,eko" + 
        "sp_change_users_login update_one,"+$BIGRAM+"_DashboardUser,"+$BIGRAM+"_DashboardUser" +
        "sp_change_users_login update_one,"+$BIGRAM+"_MenuUser,"+$BIGRAM+"_MenuUser" +
        "sp_change_users_login update_one,"+$BIGRAM+"_SecurityUser,"+$BIGRAM+"_SecurityUser" +
        "sp_change_users_login update_one,"+$BIGRAM+"_NeptuneAdmin,"+ $BIGRAM+"_NeptuneAdmin" +
        "sp_change_users_login update_one,"+$BIGRAM+"_NeptuneUser,"+$BIGRAM+"_NeptuneUser"
            
        Out-File -FilePath $PSScriptRoot\SqlUsers.txt -Encoding Unicode -InputObject $sql_users
    }
