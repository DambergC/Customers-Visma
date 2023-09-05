<#
.Synopsis
   Detta skript kan du änvända för att underlätta vid uppgradering av Personec P
.DESCRIPTION
   Funktioner i skripet
	- XML - Creates XML-file with default value
	- Backup - filebackup excl. logfiles 
	
.EXAMPLE
   InstallSupport-PersonecP.ps1 -backup
   Backup av filstruktur 
.EXAMPLE
   InstallSupport-PersonecP.ps1 -InventorySystem

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
   Version 1.2 - Buggfixar
   Version 2.0 - XML-fil för bigram samt borttagning av pwd
   
#>

#------------------------------------------------#
# Parameters

Param (
	[Parameter(Mandatory = $false)]
	[Switch]$XML,
	[Parameter(Mandatory = $false)]
	[Switch]$Backup,
	[Parameter(Mandatory = $false)]
	[Switch]$Password,
	[Parameter(Mandatory = $false)]
	[Switch]$InventoryConfig,
	[Parameter(Mandatory = $false)]
	[Switch]$InventorySystem,
	[Parameter(Mandatory = $false)]
	[Switch]$ShutdownServices,
	[Parameter(Mandatory = $false)]
	[Switch]$CopyReports,
	[Parameter(Mandatory = $false)]
	[Switch]$SqlQuery,
	[Parameter(Mandatory = $false)]
	[Switch]$DBAbackup,
	[Parameter(Mandatory = $false)]
	[Switch]$Sql_Import_From_Old_DB,
	[Parameter(Mandatory = $false)]
	[Switch]$QRUser
)

# Check if XML-file exist, if not... create default
if ($XML -eq $true)
{
	$XMLexist = (test-path -Path "$PSScriptRoot\ScriptConfig.XML")
	if ($XMLexist -eq $false)
	{
		Add-Type -AssemblyName Microsoft.VisualBasic
		$bigramtoXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter BIGRAM", "Enter customer bigram", "BIGRAM")
		
		#skapa xml-dokument
		$xmlWriter = New-Object System.XMl.XmlTextWriter("$PSScriptRoot\ScriptConfig.XML", $null)
		$xmlWriter.Formatting = 'Indented'
		$xmlWriter.Indentation = 1
		$XmlWriter.IndentChar = "`t"
		
		$xmlWriter.WriteStartDocument()
		
		$xmlWriter.WriteStartElement("Configuration") # Configuration Startnode
		
		$xmlWriter.WriteElementString("CustomerBigram", "$BigramToXML")
		$xmlWriter.WriteElementString("DBscriptPath", "D:\Visma")
		$xmlWriter.WriteElementString("LongVersion", "23040")
		$xmlWriter.WriteElementString("ShortVersion", "23040")
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
[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"


$BigramXML = $xmlfile.configuration.customerbigram
$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
$longversionXML = $xmlfile.configuration.longversion
$shortverionXML = $xmlfile.configuration.shortversion

#Password for BIGRAM_Sec account
$Sec_PW = "Visma2016!"

#Password when for BIGRAM_QRRead when creating the query
$QRReadPW = "Visma2016!"

# Todays date (used with backupfolder and Pre-Check txt file
$Today = (get-date -Format yyyyMMdd)
$Time = (get-date -Format HH:MM:ss)

# Services to check
$services = "Ciceron Server Manager", "PersonecPBatchManager$BigramXML", "PersonecPUtdataExportImportService$BigramXML", "RSPFlexService$BigramXML", "W3SVC", "World Wide Web Publishing Service"

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

# Function 

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

#Generate-RandomPassword 10


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


#region todo things...

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

if ($InventorySystem -eq $true)
{
	
	$folder = (test-path -Path "D:\visma\Install\Backup\$Today\")
	
	if ($folder -eq $false)
	{
		New-Item -Path "d:\visma\install\backup\" -ItemType Directory -Name $Today
	}
	
	# Check and document services
	foreach ($Service in $Services)
	{
		$InfoOnService = Get-WmiObject Win32_Service | where Name -eq $Service | Select-Object name, startname, state, Startmode -ErrorAction SilentlyContinue
		#Write-Log -Level INFO -Message "Checking status for $service "
		$data += $InfoOnService
	}
	
	# Send data to file about services
	$time | Out-File "$PSScriptRoot\$today\Services_$Today_$time.txt" -Append
	$data | Out-File "$PSScriptRoot\$today\Services_$Today_$time.txt" -Append
	
	# Check dotnet version installed and send to file
	#$dotnet = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where { $_.PSChildName -Match '^(?!S)\p{L}' } | Select PSChildName, version | Sort-Object version -Descending | Out-File $PSScriptRoot\$today\DotNet_$today.txt -Append
	
	# get installed software
	
	$installed = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
								  'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction Ignore | Where-Object publisher -eq 'Visma' | Select-Object -Property DisplayName, DisplayVersion, Publisher | Sort-Object -Property DisplayName
	$time | Out-File "$PSScriptRoot\$today\InstalledSoftware_$Today_$time.txt" -Append
	$installed | Out-File "$PSScriptRoot\$today\InstalledSoftware_$Today_$time.txt" -Append
	
	
}

if ($InventoryConfig -eq $true)
{
	
	#endregion
	
	#region UserSSo check
	
	$UseSSOBackup = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$BigramXML\$BigramXML\Login\Web.config")
	
	if ($UseSSOBackup -eq $true)
	{
		[XML]$UseSSO = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\$BigramXML\Login\Web.config" -ErrorAction SilentlyContinue
		$time | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT1 = 'SINGLESIGNON' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'UseSSO' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$usesso.configuration.appsettings.add.where{ $_.key -eq 'UseSSo' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		
	}
	Else
	{
		write-host "No web.config for UseSSO in backup"
	}
	#endregion
	
	#region förhandling check
	
	
	$forhandling = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$BigramXML\pfh\services\Web.config")
	
	if ($forhandling -eq $true)
	{
		[XML]$forhandlingsettings = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\pfh\services\Web.config" -ErrorAction SilentlyContinue
		$time | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT1 = 'FÖRHANDLING' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PotEditable' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$forhandlingsettings.configuration.appsettings.add.where{ $_.key -eq 'PotEditable' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		
	}
	Else
	{
		write-host "No web.config for forhandling in backup"
	}
	
	#endregion
	
	#region Befolkning
	
	$befolkningBackupAG = (Test-path -Path "$PSScriptRoot\$today\Wwwroot\$BigramXML\PPP\Personec_AG\web.config")
	
	if ($befolkningBackupAG -eq $true)
	{
		[XML]$UseBEfolkAG = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\PPP\Personec_AG\web.config" -ErrorAction SilentlyContinue
		$time | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT1 = 'BEFOLKNINGSREGISTER AG-web.config' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'BefolkningsregisterConfigFileName' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$UseBEfolkAG.configuration.appsettings.add.where{ $_.key -eq 'BefolkningsregisterConfigFileName' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'BefolkningsregisterConfigName' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$UseBEfolkAG.configuration.appsettings.add.where{ $_.key -eq 'BefolkningsregisterConfigName' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append
	}
	else
	{
		write-host "No web.config for befolkning in backup för AG web.config"
	}
	
	#endregion
	
	#region PStid.ini
	
	$pathPStid = (Test-Path "$PSScriptRoot\$today\programs\$BigramXML\ppp\Personec_p\pstid.ini")
	
	if ($pathPStid -eq $true)
	{
		$pstid = Get-IniFile "$PSScriptRoot\$today\programs\$BigramXML\ppp\Personec_p\pstid.ini"
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
	
	#endregion
	
	#region Egna rapporter check
	
	$ReportsBackupPPP = (Test-Path "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_P_web\Lon\cr\rpt")
	
	if ($ReportsBackupPPP -eq $true)
	{
		$rapport = Get-ChildItem -Recurse "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_P_web\Lon\cr\rpt"
		$time | Out-File "$PSScriptRoot\$today\ReportsPPP_$Today.txt" -Append
		$rapport | out-file "$PSScriptRoot\$today\reportsPPP_$Today.txt" -Append
	}
	else
	{
		write-host "No reports for PPP in backup"
	}
	
	$ReportsBackupAG = (Test-Path "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_AG\CR\rpt")
	
	if ($ReportsBackupAG -eq $true)
	{
		$rapport = Get-ChildItem -Recurse "$PSScriptRoot\$Today\Wwwroot\$BigramXML\PPP\Personec_AG\CR\rpt"
		$time | Out-File "$PSScriptRoot\$today\ReportsAG_$Today.txt" -Append
		$rapport | out-file "$PSScriptRoot\$today\reportsAG_$Today.txt" -Append
	}
	else
	{
		write-host "No reports for AG in backup"
	}
	
	#endregion
	
	#region Batch check
	
	$BatchBackup = (Test-Path "$PSScriptRoot\$today\Programs\$BigramXML\PPP\Personec_P\batch.config")
	
	if ($BatchBackup -eq $true)
	{
		[xml]$Batch = Get-Content "$PSScriptRoot\$today\Programs\$BigramXML\PPP\Personec_P\batch.config" -ErrorAction SilentlyContinue
		
		$time | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT1 = 'BATCHUSER-cHECK' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$Batch.configuration.appsettings.add.where{ $_.key -eq 'sysuser' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$Batch.configuration.appsettings.add.where{ $_.key -eq 'SysPassword' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		
		
	}
	Else
	{
		write-host "No batch"
	}
	#endregion
	
	#region PIA Webconfig check
	$PiaBackup = (Test-Path "$PSScriptRoot\$today\wwwroot\$BigramXML\PIA\PUF_IA Module\web.config")
	
	if ($PiaBackup -eq $true)
	{
		[XML]$PIA = Get-Content "$PSScriptRoot\$today\Wwwroot\$BigramXML\PIA\PUF_IA Module\web.config" -ErrorAction SilentlyContinue
		$time | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT1 = 'PIA CHECK' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PPP Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'P.Database.User' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PPP Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'P.Database.Password' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PUD Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'U.Database.User' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PUD Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'U.Database.Password' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PFH Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'F.Database.User' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'PFH Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'F.Database.Password' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'Service Username' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'ServiceUser.Login' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT2 = 'Service Password' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$PIA.configuration.appsettings.add.where{ $_.key -eq 'ServiceUser.secret' }.value | Out-File "$PSScriptRoot\$today\data.txt" -Append
		$TEXT3 = '-----------------' | Out-File "$PSScriptRoot\$today\data.txt" -Append
		
	}
	Else
	{
		WRITE-HOST "No web.config for PIA in backup"
	}
	#endregion
	
	#region AppPool check
	
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
		$time | Out-File "$PSScriptRoot\$today\ApplicationPoolIdentity_$Today.txt" -Append
		$appPoolResultat | out-file "$PSScriptRoot\$today\ApplicationPoolIdentity_$Today.txt" -Append
		
	}
	
	catch
	{
		write-host "no app-pool"
	}
	
	#endregion
	
}


#------------------------------------------------#
# Backup of folders

# Copy to backup
if ($Backup -eq $true)
{
	
	
	Copy-ItemWithProgress D:\Visma\Wwwroot\ D:\Visma\Install\backup\$Today\wwwroot\ /e /xf *.log, *.svclog -ErrorAction SilentlyContinue
	Copy-ItemWithProgress D:\Visma\Programs\ D:\Visma\Install\backup\$Today\programs\ /e /xf *.log -ErrorAction SilentlyContinue
	
}


#------------------------------------------------#
# Stop services

if ($ShutdownServices -eq $true)
{
	# Stop WWW site Bigram
	Stop-IISSite -Name $BigramXML -Verbose -Confirm:$false
	#Write-Log -Level INFO -Message "Stopped website for " + $BigramXML 
	
	foreach ($Service in $Services)
	{
		Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue -Verbose
		#Write-Log -Level INFO -Message "Stopped $service if it was running"
		
	}
	
}



#------------------------------------------------#
# Get Sql Query
if ($SqlQuery -eq $true)
{
	
	 = @"
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
"@
	

	$time | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
	$SQL_queries | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
}

#------------------------------------------------#
#SQL Query for importing accounts
if ($Sql_Import_From_Old_DB -eq $true)
{
	$sql_users = @"
#------------------------------------------------#
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
"@

	$time | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
	$sql_users | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
}

#------------------------------------------------#
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

#------------------------------------------------#
#QRRead query
if ($QRUser -eq $true)
{
	$QRRead_users = @"
#------------------------------------------------#
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
"@


	$time | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
	$QRRead_users | Out-File "$PSScriptRoot\$today\SQL_queries.txt" -Append
}
#------------------------------------------------#
