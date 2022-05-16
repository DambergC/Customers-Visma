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
   InstallSupport-PersonecP.ps1 -Inventory
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
    [Switch]$Inventory,
    [Parameter(Mandatory=$false)]
    [Switch]$ShutdownServices,
    [Parameter(Mandatory=$false)]
    [Switch]$CopyReports
    )


#------------------------------------------------#
# Variables & arrays

    #$bigram = read-host 'Bigram?'
    $bigram = 'HAEDAK'
    
    # Todays date (used with backupfolder and Pre-Check txt file
    $Today = (get-date -Format yyyyMMdd)
    
    # Services to check
    $services = "Ciceron Server Manager","PersonecPBatchManager","Personec P utdata export Import Service","RSPFlexService"
    
    # Array to save data
    $data = @()

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

      #write-log -Level INFO -Message "Running script"
#------------------------------------------------#
# Service and web.config

if ($Inventory -eq $true)
{
   # Check and document services
    foreach ($Service in $Services)
    {
        $InfoOnService = Get-WmiObject Win32_Service | where Name -eq $Service | Select-Object name,startname,state,Startmode -ErrorAction SilentlyContinue
        #Write-Log -Level INFO -Message "Checking status for $service "
        $data += $InfoOnService
    }
    
    # Send data to file about services
    $data | Out-File $PSScriptRoot\$today\Services_$Today.txt
    
    # Check dotnet version installed and send to file
    $dotnet = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where { $_.PSChildName -Match '^(?!S)\p{L}'} | Select PSChildName, version | Sort-Object version -Descending | Out-File $PSScriptRoot\$today\DotNet_$today.txt
   

    # UserSSo check
    [XML]$UseSSO = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\$bigram\Login\Web.config" -ErrorAction SilentlyContinue
    $UseSSO.configuration.appSettings.add | out-file "$PSScriptRoot\$today\UseSSO_Check_$Today.txt" 

    # PIA Batch check
    [XML]$Batch = Get-Content "$PSScriptRoot\$today\Programs\$bigram\PPP\Personec_P\batch.config" -ErrorAction SilentlyContinue
    $Batch.configuration.appSettings.add | out-file "$PSScriptRoot\$today\Batch_$Today.txt"


    # PIA Webconfig check
    [XML]$PIAWEB = Get-Content "$PSScriptRoot\$today\Wwwroot\$bigram\PIA\PUF_IA Module\web.config" -ErrorAction SilentlyContinue
    $PIAWEB.configuration.appSettings.add | out-file "$PSScriptRoot\$today\PIAWebconfig_$Today.txt"

    # AppPool check
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
    $appPoolResultat |out-file "$PSScriptRoot\$today\ApplicationPoolIdentity_$Today.txt"

}

    

#------------------------------------------------#
# Backup of folders

# Copy to backup
if ($Backup -eq $true)
    {
       #write-log -Level INFO -Message "Start copy from Programs to backup"
       copy-item D:\visma\Programs -Destination $PSScriptRoot\$today\Programs -Recurse -Exclude *.log -Verbose
       #write-log -Level INFO -Message "Finished copy from Programs to backup"
       #write-log -Level INFO -Message "Start copy from WWWroot to backup"
       copy-item D:\visma\Wwwroot -Destination $PSScriptRoot\$Today\Wwwroot -Recurse -Exclude *.log -Verbose
       #write-log -Level INFO -Message "Finished copy from WWWroot to backup" 
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
