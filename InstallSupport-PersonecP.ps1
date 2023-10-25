<#
	.Synopsis
		Script to support technician with Personec P
	
	.DESCRIPTION
		This Script supports the work with upgrading Peronec P and task connected to the product
	
	.PARAMETER XML
		A description of the XML parameter.
	
	.PARAMETER Backup
		A description of the Backup parameter.
	
	.PARAMETER SqlQueries
		A description of the SqlQueries parameter.
	
	.PARAMETER InventorySystem
		A description of the InventorySystem parameter.
	
	.PARAMETER InventorySettings
		A description of the InventorySettings parameter.
	
	.PARAMETER InventoryPasswords
		A description of the InventoryPasswords parameter.
	
	.PARAMETER Password
		A description of the Password parameter.
	
	.PARAMETER ShutdownServices
		A description of the ShutdownServices parameter.
	
	.PARAMETER CopyReports
		A description of the CopyReports parameter.
	
	.PARAMETER DBAbackup
		A description of the DBAbackup parameter.
	
	.EXAMPLE
		InstallSupport-PersonecP.ps1 -backup
		Backup av filstruktur
	
	.EXAMPLE
		InstallSupport-PersonecP.ps1 -InventorySystem
	
	.EXAMPLE
		InstallSupport-PersonecP.ps1 -InventoryConfig
		
	
	.EXAMPLE
		InstallSupport-PersonecP.ps1 -ShutdownServices
	
	.NOTES
		Filename: Pre-InstallPersonec_P.ps1
		Author: Christian Damberg
		Website: https://www.damberg.org
		Email: christian@damberg.org
		Modified date: 2023-10-24
		Version 1.0 - First release
		Version 1.1 - Updated step inventory to extract appool settings
		Version 1.2 - Buggfixar
		Version 2.0 - XML-fil and remove password
		Version 2.1 - Removed Swedish
		Version 2.2 - Added scheduler and message broker services to check and stop.
#>
param
(
	[Parameter(Mandatory = $false)]
	[Switch]$XML,
	[Parameter(Mandatory = $false)]
	[Switch]$Backup,
	[Parameter(Mandatory = $false)]
	[Switch]$SqlQueries,
	[Parameter(Mandatory = $false)]
	[Switch]$InventorySystem,
	[Parameter(Mandatory = $false)]
	[Switch]$InventorySettings,
	[Parameter(Mandatory = $false)]
	[Switch]$InventoryPasswords,
	[Parameter(Mandatory = $false)]
	[Switch]$Password,
	[Parameter(Mandatory = $false)]
	[Switch]$ShutdownServices,
	[Parameter(Mandatory = $false)]
	[Switch]$CopyReports,
	[Parameter(Mandatory = $false)]
	[Switch]$DBAbackup
)



# Check if XML-file exist, if not... create default
if ($XML -eq $true)
{
	$XMLexist = (test-path -Path "$PSScriptRoot\ScriptConfig.XML")
	if ($XMLexist -eq $false)
	{
		Add-Type -AssemblyName Microsoft.VisualBasic
		$bigramtoXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter BIGRAM", "Enter customer bigram", "BIGRAM")
		
		#Create XML
		$xmlWriter = New-Object System.XMl.XmlTextWriter("$PSScriptRoot\ScriptConfig.XML", $null)
		$xmlWriter.Formatting = 'Indented'
		$xmlWriter.Indentation = 1
		$XmlWriter.IndentChar = "`t"
		
		$xmlWriter.WriteStartDocument()
		
		$xmlWriter.WriteStartElement("Configuration") # Configuration Startnode
		
		$xmlWriter.WriteElementString("CustomerBigram", "$BigramToXML")
		$xmlWriter.WriteElementString("DBscriptPath", "D:\Visma")
		$xmlWriter.WriteElementString("LongVersion", "23100")
		$xmlWriter.WriteElementString("ShortVersion", "23100")
		$xmlWriter.WriteEndElement() # Configuration endnode
		$xmlWriter.Flush()
		$xmlWriter.Close()
	}
	else
	{
		
		Add-Type -AssemblyName PresentationCore, PresentationFramework
		$ButtonType = [System.Windows.MessageBoxButton]::Ok
		$MessageIcon = [System.Windows.MessageBoxImage]::Information
		$MessageBody = "There is already a xml-file called Scriptconfig.xml?"
		$MessageTitle = "XML exist"
		
		$Result = [System.Windows.MessageBox]::Show($MessageBody, $MessageTitle, $ButtonType, $MessageIcon)
		
	}
	
}

#region Variables & arrays

$XMLexist = (test-path -Path "$PSScriptRoot\ScriptConfig.XML")

if ($XMLexist -eq $false)


{

    	Add-Type -AssemblyName PresentationCore, PresentationFramework
		$ButtonType = [System.Windows.MessageBoxButton]::Ok
		$MessageIcon = [System.Windows.MessageBoxImage]::Information
		$MessageBody = "You need to create an xml-file... USE -xml "
		$MessageTitle = "XML Missing..."
        
	    $Result = [System.Windows.MessageBox]::Show($MessageBody, $MessageTitle, $ButtonType, $MessageIcon)

        exit


}

else

{

[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"

$BigramXML = $xmlfile.configuration.customerbigram
$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
$longversionXML = $xmlfile.configuration.longversion
$shortverionXML = $xmlfile.configuration.shortversion

}




# Todays date (used with backupfolder and Pre-Check txt file
$Today = (get-date -Format yyyyMMdd)
$Time = (get-date -Format HH:MM:ss)

# Services to check
$services = "Scheduler", "Ciceron Server Manager","NeptuneMB_$BigramXML", "PersonecPBatchManager$BigramXML", "PersonecPUtdataExportImportService$BigramXML", "RSPFlexService$BigramXML", "W3SVC", "World Wide Web Publishing Service"

# Array to save data
$data = @()

#Array to save SQL queries<zx<x<zx<zx<
$SQL_queries = @()

$logfile = "$PSScriptRoot\$today\Pre-InstallPersonec_P_$today.log"

#endregion

#region variables for database or database user to be cleaner in the string, NO NEED TO CHANGE THESE!

#QRRead user
$QRRead = $BigramXML + "_QRRead"
#PPP DB
$DB_PPP = $BigramXML + "_PPP"
#PFH DB
$DB_PFH = $BigramXML + "_PFH"
#PUD DB
$DB_PUD = $BigramXML + "_PUD"
#PAG DB
$DB_PAG = $BigramXML + "_PAG"
#Neptune DB
$DB_Neptune = $BigramXML + "Neptune"
#Sec user for IIS
$Sec_User = $BigramXML + "_Sec"
#DashboardUser
$DBUser_DU = $BigramXML + "_DashboardUser"
#MenuUser
$DBUser_MU = $BigramXML + "_MenuUser"
#SecurityUser
$DBUser_SU = $BigramXML + "_SecurityUser"
#NeptuneAdmin
$DBUser_NA = $BigramXML + "_NeptuneAdmin"
#NeptuneUser
$DBUser_NU = $BigramXML + "_NeptuneUser"

#endregion

#region Function 

function Generate-RandomPassword
{
	param (
		[Parameter(Mandatory)]
		[int]$length
	)
	
	$charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
	
	$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
	$bytes = New-Object byte[]($length)
	
	$rng.GetBytes($bytes)
	
	$result = New-Object char[]($length)
	
	for ($i = 0; $i -lt $length; $i++)
	{
		$result[$i] = $charSet[$bytes[$i] % $charSet.Length]
	}
	
	return -join $result
}

#Read more: https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html#ixzz8Bgs4333S

Function Write-Log
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $False)]
		[ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
		[String]$Level = "INFO",
		[Parameter(Mandatory = $True)]
		[string]$Message
	)
	
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$Line = "$Stamp $Level $Message"
	"$Stamp $Level $Message" | Out-File -Encoding utf8 $logfile -Append
}

Function Copy-ItemWithProgress
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
		[string[]]$RobocopyArgs
	)
	
	$ScanLog = [IO.Path]::GetTempFileName()
	$RoboLog = [IO.Path]::GetTempFileName()
	$ScanArgs = $RobocopyArgs + "/ndl /TEE /bytes /Log:$ScanLog /nfl /L".Split(" ")
	$RoboArgs = $RobocopyArgs + "/ndl /TEE /bytes /Log:$RoboLog /NC".Split(" ")
	
	# Launch Robocopy Processes
	write-verbose ("Robocopy Scan:`n" + ($ScanArgs -join " "))
	write-verbose ("Robocopy Full:`n" + ($RoboArgs -join " "))
	$ScanRun = start-process robocopy -PassThru -WindowStyle Hidden -ArgumentList $ScanArgs
	$RoboRun = start-process robocopy -PassThru -WindowStyle Hidden -ArgumentList $RoboArgs
	
	# Parse Robocopy "Scan" pass
	$ScanRun.WaitForExit()
	$LogData = get-content $ScanLog
	if ($ScanRun.ExitCode -ge 8)
	{
		$LogData | out-string | Write-Error
		throw "Robocopy $($ScanRun.ExitCode)"
	}
	$FileSize = [regex]::Match($LogData[-4], ".+:\s+(\d+)\s+(\d+)").Groups[2].Value
	write-verbose ("Robocopy Bytes: $FileSize `n" + ($LogData -join "`n"))
	
	# Monitor Full RoboCopy
	while (!$RoboRun.HasExited)
	{
		$LogData = get-content $RoboLog
		$Files = $LogData -match "^\s*(\d+)\s+(\S+)"
		if ($Files -ne $Null)
		{
			$copied = ($Files[0 .. ($Files.Length - 2)] | %{ $_.Split("`t")[-2] } | Measure -sum).Sum
			if ($LogData[-1] -match "(100|\d?\d\.\d)\%")
			{
				write-progress Copy -ParentID $RoboRun.ID -percentComplete $LogData[-1].Trim("% `t") $LogData[-1]
				$Copied += $Files[-1].Split("`t")[-2] /100 * ($LogData[-1].Trim("% `t"))
			}
			else
			{
				write-progress Copy -ParentID $RoboRun.ID -Complete
			}
			write-progress ROBOCOPY -ID $RoboRun.ID -PercentComplete ($Copied/$FileSize * 100) $Files[-1].Split("`t")[-1]
		}
	}
	
	# Parse full RoboCopy pass results, and cleanup
	(get-content $RoboLog)[-11 .. -2] | out-string | Write-Verbose
	[PSCustomObject]@{ ExitCode = $RoboRun.ExitCode }
	remove-item $RoboLog, $ScanLog
}

function Get-IniFile
{
	param (
		[parameter(Mandatory = $true)]
		[string]$filePath
	)
	$anonymous = "NoSection"
	$ini = @{ }
	switch -regex -file $filePath
	{
		"^\[(.+)\]$" # Section  
		{
			$section = $matches[1]
			$ini[$section] = @{ }
			$CommentCount = 0
		}
		"^(;.*)$" # Comment  
		{
			if (!($section))
			{
				$section = $anonymous
				$ini[$section] = @{ }
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
				$ini[$section] = @{ }
			}
			$name, $value = $matches[1 .. 2]
			$ini[$section][$name] = $value
		}
	}
	return $ini
}

#endregion

#region Passwordgenerator

if ($Password -eq $true)
{
	
    
    $passwordGenerate = Generate-RandomPassword -length 15
	
	Set-Clipboard -Value $passwordGenerate
	
	Add-Type -AssemblyName PresentationCore, PresentationFramework
	$ButtonType = [System.Windows.MessageBoxButton]::OK
	$MessageIcon = [System.Windows.MessageBoxImage]::Information
	$MessageBody = "The following password has been generated and sent to your clipboard, -->    $passwordGenerate  <--"
	$MessageTitle = "Password generated!"
	
	$Result = [System.Windows.MessageBox]::Show($MessageBody, $MessageTitle, $ButtonType, $MessageIcon)
}

#endregion

#region Inventorysystem

if ($InventorySystem -eq $true)
{
	# Check if backupfolder exist
	$folder = (test-path -Path "D:\visma\Install\Backup\$Today\")
	
	if ($folder -eq $false)
	{
		New-Item -Path "d:\visma\install\backup\" -ItemType Directory -Name $Today
	}
	
	# Inventory services and status
	foreach ($Service in $Services)
	{
		$InfoOnService = Get-WmiObject Win32_Service | where Name -eq $Service | Select-Object name, startname, state, Startmode -ErrorAction SilentlyContinue

                                $object = New-Object -TypeName PSObject
                                $object | Add-Member -MemberType NoteProperty -Name 'Tjänst' -Value $InfoOnService.name
                                $object | Add-Member -MemberType NoteProperty -Name 'Konto' -Value $InfoOnService.Startname
                                $object | Add-Member -MemberType NoteProperty -Name 'Status' -Value $InfoOnService.state
                                $object | Add-Member -MemberType NoteProperty -Name 'Startdatum' -Value $InfoOnService.startmode

                                $data += $object
	}

	$data | Out-File "$PSScriptRoot\$today\Data_$Today.txt" -Append
	

$data2 = @()
	
$installed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction Ignore | Where-Object publisher -eq 'Visma' | Select-Object -Property DisplayName, DisplayVersion, Publisher | Sort-Object -Property DisplayName
	
    foreach ($inst in $installed)

    {

                                $object = New-Object -TypeName PSObject
                                $object | Add-Member -MemberType NoteProperty -Name 'Applikation' -Value $inst.displayname
                                $object | Add-Member -MemberType NoteProperty -Name 'Version' -Value $inst.displayversion
                                $object | Add-Member -MemberType NoteProperty -Name 'Utgivare' -Value $inst.publisher

                                $data2 += $object
    
    }

    #$time | Out-File "$PSScriptRoot\$today\InstalledSoftware_$today.txt" -Append
	$data2 | Out-File "$PSScriptRoot\$today\data_$today.txt" -Append
	
	try
	{
		$appPools = Get-WebConfiguration -Filter '/system.applicationHost/applicationPools/add'
		$appPoolResultat = [System.Collections.ArrayList]::new()
		
		foreach ($appPool in $appPools)
		{
			
			[void]$appPoolResultat.add([PSCustomObject]@{
					Name = $appPool.name
					User = $appPool.ProcessModel.UserName
					#Password = $appPool.ProcessModel.Password
				})
			
		}
		#$time | Out-File "$PSScriptRoot\$today\ApplicationPoolIdentity_$Today.txt" -Append
		$appPoolResultat | out-file "$PSScriptRoot\$today\data_$Today.txt" -Append
		
	}
	
	catch
	{
		write-host "no app-pool"
	}

}
#endregion

#region InventorySettings

$data3 = @()


if ($InventorySettings -eq $true)
{

	$UseSSOBackup = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$BigramXML\$BigramXML\Login\Web.config")
	
	if ($UseSSOBackup -eq $true)
	{

		[XML]$UseSSO = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\$BigramXML\Login\Web.config" -ErrorAction SilentlyContinue


                                $object = New-Object -TypeName PSObject
                                $object | Add-Member -MemberType NoteProperty -Name 'useSSO' -Value $usesso.configuration.appsettings.add.where{ $_.key -eq 'UseSSo' }.value
                                
                                $data3 += $object
                                $data3 | Out-File "$PSScriptRoot\$today\data_$Today.txt" -Append

    }
    	
	Else
	{
		write-host "No web.config for UseSSO in backup"
	}


$data4 = @()


	$befolkningBackupAG = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$BigramXML\PPP\Personec_AG\web.config")
	
	if ($befolkningBackupAG -eq $true)
	{
		[XML]$UseBEfolkAG = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\PPP\Personec_AG\web.config" -ErrorAction SilentlyContinue

                                $object = New-Object -TypeName PSObject
                                $object | Add-Member -MemberType NoteProperty -Name 'BefolkningsregisterConfigFileName' -Value $UseBEfolkAG.configuration.appsettings.add.where{ $_.key -eq 'BefolkningsregisterConfigFileName' }.value
                                $object | Add-Member -MemberType NoteProperty -Name 'BefolkningsregisterConfigName' -Value $UseBEfolkAG.configuration.appsettings.add.where{ $_.key -eq 'BefolkningsregisterConfigName' }.value

                                $data4 += $object
                                $data4 | Out-File "$PSScriptRoot\$today\data_$Today.txt" -Append


	}
	else
	{
		write-host "No web.config for befolkning in backup för AG web.config"
	}



$ReportsBackupPPP = (Test-Path "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_P_web\Lon\cr\rpt")
	
	if ($ReportsBackupPPP -eq $true)
	{
		$rapport = Get-ChildItem -Recurse "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_P_web\Lon\cr\rpt"

		$rapport | out-file "$PSScriptRoot\$today\data_$Today.txt" -Append
	}
	else
	{
		write-host "No reports for PPP in backup"
	}


	
	$ReportsBackupAG = (Test-Path "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_AG\CR\rpt")
	
	if ($ReportsBackupAG -eq $true)
	{
		$rapport = Get-ChildItem -Recurse "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_AG\CR\rpt"

		$rapport | out-file "$PSScriptRoot\$today\data_$Today.txt" -Append
	}
	else
	{
		write-host "No reports for AG in backup"
	}

}


if ($InventoryPasswords -eq $true)
{

$data5 = @()

#Region Passwords

		$pstid = Get-IniFile "$PSScriptRoot\$today\programs\$BigramXML\ppp\Personec_p\pstid.ini" -ErrorAction SilentlyContinue
        [xml]$Batch = Get-Content "$PSScriptRoot\$today\Programs\$BigramXML\PPP\Personec_P\batch.config" -ErrorAction SilentlyContinue
        [XML]$PIA = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\PIA\PUF_IA Module\web.config" -ErrorAction SilentlyContinue
		
                                $object = New-Object -TypeName PSObject
                                $object | Add-Member -MemberType NoteProperty -Name 'NeptuneUser' -Value $PSTID.styr.NeptuneUser
                                $object | Add-Member -MemberType NoteProperty -Name 'NeptunePassword' -Value $PSTID.styr.NeptuneUser
                                $object | Add-Member -MemberType NoteProperty -Name 'Batchuser' -Value $Batch.configuration.appsettings.add.where{ $_.key -eq 'sysuser' }.value
                                $object | Add-Member -MemberType NoteProperty -Name 'BatchPassword' -Value $Batch.configuration.appsettings.add.where{ $_.key -eq 'SysPassword' }.value
                                
                                $object | Add-Member -MemberType NoteProperty -Name 'PPP Username' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'P.Database.User' }.value
                                $object | Add-Member -MemberType NoteProperty -Name 'PPP Password' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'P.Database.Password' }.value
                                
                                $object | Add-Member -MemberType NoteProperty -Name 'PUD Username' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'U.Database.User' }.value
                                $object | Add-Member -MemberType NoteProperty -Name 'PUD Password' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'U.Database.Password' }.value
                                
                                $object | Add-Member -MemberType NoteProperty -Name 'PFH Username' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'F.Database.User' }.value
                                $object | Add-Member -MemberType NoteProperty -Name 'PFH Password' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'F.Database.Password' }.value
                                
                                $object | Add-Member -MemberType NoteProperty -Name 'Service Username' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'ServiceUser.Login' }.value
                                $object | Add-Member -MemberType NoteProperty -Name 'Service Password' -Value $PIA.configuration.appsettings.add.where{ $_.key -eq 'serviceUser.Secret' }.value
                                $data5 += $object
     


     
$data5 | format-list
}


#region backup


# Copy to backup
if ($Backup -eq $true)
{
	
	
	Copy-ItemWithProgress D:\Visma\Wwwroot\ D:\Visma\Install\backup\$Today\wwwroot\ /e /xf *.log, *.svclog -ErrorAction SilentlyContinue
	Copy-ItemWithProgress D:\Visma\Programs\ D:\Visma\Install\backup\$Today\programs\ /e /xf *.log -ErrorAction SilentlyContinue
	
}


#endregion

#region stop services
#------------------------------------------------#
# Stop services

if ($ShutdownServices -eq $true)
{
	# Stop WWW site Bigram
	Stop-IISSite -Name $BigramXML -Verbose -Confirm:$false
	
	foreach ($Service in $Services)
	{
		Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue -Verbose
	
		
	}
	
}
#endregion

#region SQLQueries

if ($SqlQueries -eq $true)
{

$QRReadPW = Generate-RandomPassword -length 15
	
$SQL_queries = @"
#------------------------------------------------#
# SQL Query for update scripts
#------------------------------------------------#

##Personic P
USE $DB_PPP
SELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\mRSPu$shortverionXML.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\mRSPview.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\mRSPproc.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\mRSPtriggers.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\mRSPgra.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\msDBUPDATERIGHTSP.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$longversionXML\PPPds_Feltexter.sql
SELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc
#------------------------------------------------#
#Personic U
USE $DB_PUD
rSELECT * FROM dbo.PU_VERSIONSINFO
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$longversionXML\mPSUu$shortverionXML.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$longversionXML\mPSUproc.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$longversionXML\mPSUview.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$longversionXML\mPSUgra.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$longversionXML\msdbupdaterightsU.sql
SELECT * FROM dbo.PU_VERSIONSINFO
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc
#------------------------------------------------#
##Personic PFH
USE $DB_PFH
SELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$longversionXML\mPSFu$short_db_version.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$longversionXML\mPSFproc.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$longversionXML\mPSFview.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$longversionXML\mPSFgra.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$longversionXML\msDBUPDATERIGHTSF.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$longversionXML\PFHds_Feltexter.sql
SELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc
#------------------------------------------------# 
"@

$SQL_queries | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append


$QRRead_users = @"
#------------------------------------------------#
#SQL Query for QRread accounts
USE [master]
GO
CREATE LOGIN [$QRRead] WITH PASSWORD=N'$QRReadPW', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

USE [$DB_Neptune] -- Neptune
GO
CREATE USER [$QRRead] FOR LOGIN [$QRRead]
GO
ALTER ROLE [db_datareader] ADD MEMBER [$QRRead]
GO

USE [$DB_PFH] -- Personec Förhandling
GO
CREATE USER [$QRRead] FOR LOGIN [$QRRead]
GO
GRANT EXEC TO [$QRRead]
GO
ALTER ROLE [db_datareader] ADD MEMBER [$QRRead]
GO

USE [$DB_PPP] -- Personec P
GO
CREATE USER [$QRRead] FOR LOGIN [$QRRead]
GO
GRANT EXEC TO [$QRRead]
GO
ALTER ROLE [db_datareader] ADD MEMBER [$QRRead]
GO

USE [$DB_PUD] -- Personec Utdata
GO
CREATE USER [$QRRead] FOR LOGIN [$QRRead]
GO
GRANT EXEC TO [$QRRead]
GO
ALTER ROLE [db_datareader] ADD MEMBER [$QRRead]
GO

USE [$DB_PAG] -- Personec Anställningsguide
GO
CREATE USER [$QRRead] FOR LOGIN [$QRRead]
GO
ALTER ROLE [db_datareader] ADD MEMBER [$QRRead]
GO
#------------------------------------------------#
"@

$QRRead_users | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append

#------------------------------------------------#

$sql_users = @"
#------------------------------------------------#
#SQL Query for importing accounts
##Personec P
sp_change_users_login report
sp_change_users_login update_one,rspdbuser,rspdbuser
sp_change_users_login update_one,psutotint,psutotint
sp_change_users_login update_one,eko,eko
sp_change_users_login update_one,$DBUser_DU,$DBUser_DU
sp_change_users_login update_one,$DBUser_MU,$DBUser_MU
sp_change_users_login update_one,$DBUser_SU,$DBUser_SU
sp_change_users_login update_one,$DBUser_NA,$DBUser_NA
sp_change_users_login update_one,$DBUser_NU,$DBUser_NU
#------------------------------------------------#
"@

$sql_users | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append

}
#endregion

#region DBbackup


#DBABackup
if ($DBAbackup -eq $true)
{
	
	if (-not (Get-Module -name dbatools))
	{
		Install-Module dbatools -Verbose -Force
		Import-Module dbatools -Verbose -force
	}
	
	$cred = Get-Credential -Message 'Lösenordet till viwinstall behövs matas in här...' -UserName viwinstall
	Add-Type -AssemblyName Microsoft.VisualBasic
	$instans = [Microsoft.VisualBasic.Interaction]::InputBox("Vilken SQLinstans ska kollas?", "Skriv in sqlinstans", "localhost")
	$backupplats = [Microsoft.VisualBasic.Interaction]::InputBox("Vart ska backuperna sparas?", "Skriv in annan sökväg vid behov", "d:\visma")
	
	get-dbaDatabase -SqlInstance $instans -SqlCredential $cred | Select-Object -Property name, size -ExpandProperty name | Where-Object name -like '*$BigramXML*' | Out-GridView -PassThru -Title 'Välj de databaser du vill ha backup på (markera flera med att hålla ner CTRL' | foreach { Backup-DbaDatabase -SqlCredential $cred -SqlInstance $instans -Database $_ -CopyOnly -FilePath $backupplats -Verbose }
	
	
}

#endregion
