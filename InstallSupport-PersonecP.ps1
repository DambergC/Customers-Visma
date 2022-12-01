<#
.Synopsis
   Detta skript kan du änvända för att underlätta vid uppgradering av Personec P
.DESCRIPTION
   Funktioner i skripet
   - Backup av filstrukturen
   - Ta fram vissa värden från web.config som du behöver vid uppgraderingen
   - Kontroll av system
    - DotNet 4.8
    - Crystal Reports version
    - Vilka tjänster som rullar samt med vilka konton som kör dom
    - Vilka konton som applikationspoolerna körs med
    - SQLquery framtagning av textfil för att underlätta när du ska köra sql-skript i SQLCMD
    - Databasbackup
    - Serverinventering för att underlätta dokumentation för onprem kunder
    - Stopp av tjänster
.EXAMPLE
   InstallSupport-PersonecP.ps1 -backup
   Backup av filstruktur 
.EXAMPLE
   InstallSupport-PersonecP.ps1 -InventorySystem
   DotNet, Crystal reports, tjänster och applikationspooler
.EXAMPLE
   InstallSupport-PersonecP.ps1 -InventoryConfig
   Framtagning av värden som du behöver senare
.EXAMPLE
   InstallSupport-PersonecP.ps1 -ShutdownServices
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
    [Switch]$SqlQuery,
    [Parameter(Mandatory=$false)]
    [Switch]$DBAbackup,
    [Parameter(Mandatory=$false)]
    [Switch]$Sql_Import,
    [Parameter(Mandatory=$false)]
    [Switch]$QRRead,
    [Parameter(Mandatory=$false)]
    [Switch]$Fix_AppP
    )


#------------------------------------------------#
# Variables & arrays

    #$bigram = read-host 'Bigram?'
    $bigram = 'VISMA'

    #DB script path (Parent directory where you find "Install/HRM")
    $db_script_path = "D:\Visma"    

    #Long DB Version
    $long_db_version = 22100

    #Short DB Version
    $short_db_version = 22100

    $Sec_PW = "Visma2016!"

    # Todays date (used with backupfolder and Pre-Check txt file
    $Today = (get-date -Format yyyyMMdd)

    $time = (get-date -Format HH:MM:ss)
    
    # Services to check
    $services = "Ciceron Server Manager","PersonecPBatchManager","Personec P utdata export Import Service","RSPFlexService","W3SVC","World Wide Web Publishing Service"
    
    # Array to save data
    $data = @()

    #Array to save SQL queries<zx<x<zx<zx<
    $SQL_queries = @()

    $logfile = "$PSScriptRoot\$today\Pre-InstallPersonec_P_$today.log"


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
        $time | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT1 = 'SINGLESIGNON' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'UseSSO' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $usesso.configuration.appsettings.add.where{$_.key -eq 'UseSSo'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append

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
        $time | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT1 = 'FÖRHANDLING' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PotEditable' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $forhandlingsettings.configuration.appsettings.add.where{$_.key -eq 'PotEditable'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append

        }
    Else
        {
         write-host "No web.config for forhandling in backup"
        }

    ######################################
    # Befolkning

    $befolkningBackupAG = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$bigram\PPP\Personec_AG\web.config")

    if ($befolkningBackupAG -eq $true)

        {
        [XML]$UseBEfolkAG = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\PPP\Personec_AG\web.config" -ErrorAction SilentlyContinue
        $time | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT1 = 'BEFOLKNINGSREGISTER AG-web.config' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'BefolkningsregisterConfigFileName' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $UseBEfolkAG.configuration.appsettings.add.where{$_.key -eq 'BefolkningsregisterConfigFileName'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'BefolkningsregisterConfigName' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $UseBEfolkAG.configuration.appsettings.add.where{$_.key -eq 'BefolkningsregisterConfigName'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        }
    else
        {
         write-host "No web.config for befolkning in backup för AG web.config"
        }

    #######################################
    # PStid.ini

    $pathPStid = (Test-Path "$PSScriptRoot\$today\programs\$bigram\ppp\Personec_p\pstid.ini")
    
    if ($pathPStid -eq $true)

        {
        $pstid = Get-IniFile "$PSScriptRoot\$today\programs\$bigram\ppp\Personec_p\pstid.ini"
        $NeptuneUser = $PSTID.styr.NeptuneUser
        $NeptunePwd = $PSTID.styr.neptunepassword
        
        $time | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT1 = 'PSTID' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'NeptuneUser' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $NeptuneUser | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'NeptunePassword' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $NeptunePwd | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append

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

        $time | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT1 = 'BATCHUSER-cHECK' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $Batch.configuration.appsettings.add.where{$_.key -eq 'sysuser'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $Batch.configuration.appsettings.add.where{$_.key -eq 'SysPassword'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append

      
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
        $time | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT1 = 'PIA CHECK' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PPP Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'P.Database.User'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PPP Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'P.Database.Password'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PUD Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'U.Database.User'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PUD Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'U.Database.Password'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PFH Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'F.Database.User'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'PFH Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'F.Database.Password'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'Service Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'ServiceUser.Login'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT2 = 'Service Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $PIA.configuration.appsettings.add.where{$_.key -eq 'ServiceUser.secret'}.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
        $TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append

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
<#if ($FlyttaMallar -eq $true)
    {
        Remove-Item -Path "D:\Visma\wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt\*"
        Remove-Item -Path "D:\Visma\wwwroot\$bigram\PPP\Personec_AG\CR\rpt\*"
        Robocopy D:\Visma\Install\Backup\$Today\wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt\* D:\Visma\wwwroot\$bigram\PPP\Personec_P_web\Lon\cr\rpt
        Robocopy D:\Visma\Install\Backup\$Today\wwwroot\$bigram\PPP\Personec_AG\CR\rpt\* D:\Visma\wwwroot\$bigram\PPP\Personec_AG\CR\rpt
    }
#>

#------------------------------------------------#
# Get Sql Query
if ($SqlQuery -eq $true)
    {
        $query = "##Personic P" +
        "`rUSE $bigram"+"_PPP" +
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
        
        "`n`rSELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997" +
        "`rSELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc"

        $SQL_queries += $query
        $time | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
        $SQL_queries | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
    }
        
#------------------------------------------------#
#SQL Query for importing accounts
if ($Sql_Import -eq $true)
    {
        $sql_users = "##Personic P" +
        "`rsp_change_users_login report" +
        "`rsp_change_users_login update_one,rspdbuser,rspdbuser" +
        "`rsp_change_users_login update_one,psutotint,psutotint" +
        "`rsp_change_users_login update_one,eko,eko " +
        "`rsp_change_users_login update_one,"+$BIGRAM+"_DashboardUser,"+$BIGRAM+"_DashboardUser" +
        "`rsp_change_users_login update_one,"+$BIGRAM+"_MenuUser,"+$BIGRAM+"_MenuUser" +
        "`rsp_change_users_login update_one,"+$BIGRAM+"_SecurityUser,"+$BIGRAM+"_SecurityUser" +
        "`rsp_change_users_login update_one,"+$BIGRAM+"_NeptuneAdmin,"+ $BIGRAM+"_NeptuneAdmin" +
        "`rsp_change_users_login update_one,"+$BIGRAM+"_NeptuneUser,"+$BIGRAM+"_NeptuneUser"
            
        $SQL_queries += $Sql_Import
        $time | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
        $SQL_queries | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
    }

#------------------------------------------------#
#DBABackup
if ($DBAbackup -eq $true)
    {
        
        if (-not(Get-Module -name dbatools)) 
            {
                Install-Module dbatools -Verbose -Force
                Import-Module dbatools -Verbose -force
            }

        $cred = Get-Credential -Message 'Lösenordet till viwinstall behövs matas in här...' -UserName viwinstall
        Add-Type -AssemblyName Microsoft.VisualBasic
        $instans = [Microsoft.VisualBasic.Interaction]::InputBox("Vilken SQLinstans ska kollas?", "Skriv in sqlinstans", "localhost")
        $backupplats = [Microsoft.VisualBasic.Interaction]::InputBox("Vart ska backuperna sparas?", "Skriv in annan sökväg vid behov", "d:\visma")

        get-dbaDatabase -SqlInstance $instans -SqlCredential $cred | Select-Object -Property name,size -ExpandProperty name| Where-Object name -like '*$bigram*' | Out-GridView -PassThru -Title 'Välj de databaser du vill ha backup på (markera flera med att hålla ner CTRL' | foreach { Backup-DbaDatabase -SqlCredential $cred -SqlInstance $instans -Database $_ -CopyOnly -FilePath $backupplats -Verbose }


    }

#------------------------------------------------#
#QRRead query
if ($QRRead -eq $true)
    {
        $QRRead_users = "USE [master]" +
        "`rGO" +
        "`rCREATE LOGIN ["+$BIGRAM+"_QRRead] WITH PASSWORD=N'Squabble-Ungloved-Cargo0', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF" +
        "`rGO" +
        "`rUSE ["+$BIGRAM+"_Neptune] -- Neptune" +
        "`rGO" +
        "`rCREATE USER "+$BIGRAM+"_QRRead] FOR LOGIN "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rALTER ROLE [db_datareader] ADD MEMBER "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rUSE "+$BIGRAM+"_PFH] -- Personec Förhandling" +
        "`rGO" +
        "`rCREATE USER "+$BIGRAM+"_QRRead] FOR LOGIN "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rGRANT EXEC TO "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rALTER ROLE [db_datareader] ADD MEMBER "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rUSE "+$BIGRAM+"_PPP] -- Personec P" +
        "`rGO" +
        "`rCREATE USER "+$BIGRAM+"_QRRead] FOR LOGIN "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rGRANT EXEC TO "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rALTER ROLE [db_datareader] ADD MEMBER "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rUSE "+$BIGRAM+"_PUD] -- Personec Utdata" +
        "`rGO" +
        "`rCREATE USER "+$BIGRAM+"_QRRead] FOR LOGIN "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rGRANT EXEC TO "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rALTER ROLE [db_datareader] ADD MEMBER "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rUSE "+$BIGRAM+"_PAG] -- Personec Anställningsguide" +
        "`rGO" +
        "`rCREATE USER "+$BIGRAM+"_QRRead] FOR LOGIN "+$BIGRAM+"_QRRead]" +
        "`rGO" +
        "`rALTER ROLE [db_datareader] ADD MEMBER "+$BIGRAM+"_QRRead]" +
        "`rGO"

        $SQL_queries += $QRRead_users
        $time | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
        $SQL_queries | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
    }
#------------------------------------------------#
#Fix App pool
if ($Fix_AppP -eq $true)
     {
        Import-Module WebAdministration
        Set-ItemProperty IIS:\AppPools\$BIGRAM" Arbetsledare AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" Arbetstagare AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" PPP PService  Web Service AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" PReportTool AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" Schedule AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" Forhandling_AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" PFHServices AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" PoliticallyElected AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" Utdata AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
        Set-ItemProperty IIS:\AppPools\$BIGRAM" puf_ia AppPool" -name processModel  -value @{userName=$BIGRAM +"_Sec";password=$Sec_PW;identitytype=3}
    }
