<#
	.Synopsis
		Script to support technician with Personec P
	
	.DESCRIPTION
		This Script supports the work with upgrading Peronec P and task connected to the product
	
	.PARAMETER XML
		Only to be used first time to create a new Scriptconfig.xml. You need to provide BIGRAM
	
	.PARAMETER Backup
		Backup files for personec p with some exclutions
	
	.PARAMETER SqlQueries
		Creates the sql-queries needed for upgrade but also for creating Quick Report users
	
	.PARAMETER InventorySystem
		Inventory serivces, installed applications from Visma and existing applications pools
	
	.PARAMETER InventorySettings
		Inventory settings from filebackup that might be useful for you during upgrade.
	
	.PARAMETER InventoryPasswords
		Extract the passwords from the filebackup
	
	.PARAMETER Password
		Generate passwords randomly.
	
	.PARAMETER ShutdownServices
		Shutdown services and the site.
	
	.PARAMETER CopyReports
		A description of the CopyReports parameter.
	
	.PARAMETER DBAbackup
		A description of the DBAbackup parameter.
	
	.PARAMETER CertRights
		Select a cert that you want to set defaultrights to manage private key.
	
	.PARAMETER certthumbprint
		Select a cert and get thumbprint sent to clipboard.
	
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
		Version 2.3 - Added , Scheduler.txt* to exklude in backup
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
	[Switch]$DBAbackup,
	[Parameter(Mandatory = $false)]
	[Switch]$CertRights,
	[Parameter(Mandatory = $false)]
	[Switch]$certthumbprint
)

$checkVersionConfig = '24.5.0'

$releaseVerison = '24050'

$PPPversionScript = '24050'
$PUDversionScript = '24040'
$PFHversionScript = '24040'

#region XML
[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML" -ErrorAction Ignore

# Check if XML-file exist, if not... create default
if ($XML -eq $true)
{
	$XMLexist = (test-path -Path "$PSScriptRoot\ScriptConfig.XML")
	if ($XMLexist -eq $false)
	{
		Add-Type -AssemblyName Microsoft.VisualBasic
		$bigramtoXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter BIGRAM", "Enter customer bigram", "BIGRAM")
		$ReleaseVersionXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter RELEASEVERSION", "ReleaseVersion", $ReleaseVersion)
		$PPPXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PPP Version (SQL)", "VersionNumber PPP", $PPPversionScript)
		$PUDXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PUD Version (SQL)", "VersionNumber PUD", $PUDversionScript)
		$PFHXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PFH Version (SQL)", "VersionNumber PFH", $PFHversionScript)
		
		
		#Create XML
		$xmlWriter = New-Object System.XMl.XmlTextWriter("$PSScriptRoot\ScriptConfig.XML", $null)
		$xmlWriter.Formatting = 'Indented'
		$xmlWriter.Indentation = 1
		$XmlWriter.IndentChar = "`t"
		
		$xmlWriter.WriteStartDocument()
		
		$xmlWriter.WriteStartElement("Configuration") # Configuration Startnode
		
		$xmlWriter.WriteElementString("ConfigVersion", "$checkVersionConfig")
		$xmlWriter.WriteElementString("CustomerBigram", "$BigramToXML")
		$xmlWriter.WriteElementString("DBscriptPath", "D:\Visma")
		$xmlWriter.WriteElementString("ReleaseVersion", "$ReleaseVersionXML")
		$xmlWriter.WriteElementString("PPP", "$PPPXML")
		$xmlWriter.WriteElementString("PUD", "$PUDXML")
		$xmlWriter.WriteElementString("PFH", "$PFHXML")
		$xmlWriter.WriteEndElement() # Configuration endnode
		$xmlWriter.Flush()
		$xmlWriter.Close()
		
		exit
	}
	else
	{
		
		Add-Type -AssemblyName PresentationCore, PresentationFramework
		$ButtonType = [System.Windows.MessageBoxButton]::Ok
		$MessageIcon = [System.Windows.MessageBoxImage]::Information
		$MessageBody = "There is already a xml-file called Scriptconfig.xml?"
		$MessageTitle = "XML exist"
		
		$Result = [System.Windows.MessageBox]::Show($MessageBody, $MessageTitle, $ButtonType, $MessageIcon)
		
		exit
		
	}
	
}

#endregion


#region Variables & arrays

$XMLexist = (test-path -Path "$PSScriptRoot\ScriptConfig.XML")

[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"

$ConfigVersion = $xmlfile.configuration.ConfigVersion
$BigramXML = $xmlfile.configuration.customerbigram
$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
$ReleaseVersionXML = $xmlfile.configuration.ReleaseVersion
$PPPXML = $xmlfile.configuration.PPP
$PUDXML = $xmlfile.configuration.PUD
$PFHXML = $xmlfile.configuration.PFH


if ($XMLexist -eq $true)
{
	
	if ($ConfigVersion -ne $checkVersionConfig)
	{
		[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"
		
		$ConfigVersion = $xmlfile.configuration.ConfigVersion
		$BigramXML = $xmlfile.configuration.customerbigram
		$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
		$ReleaseVersionXML = $xmlfile.configuration.ReleaseVersion
		$PPPXML = $xmlfile.configuration.PPP
		$PUDXML = $xmlfile.configuration.PUD
		$PFHXML = $xmlfile.configuration.PFH
		
		Add-Type -AssemblyName Microsoft.VisualBasic
		$ReleaseVersionXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter RELEASEVERSION", "ReleaseVersion", $ReleaseVersion)
		$PPPXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PPP Version (SQL)", "VersionNumber PPP", $PPPversionScript)
		$PUDXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PUD Version (SQL)", "VersionNumber PUD", $PUDversionScript)
		$PFHXML = [Microsoft.VisualBasic.Interaction]::InputBox("Enter PFH Version (SQL)", "VersionNumber PFH", $PFHversionScript)
		
		#Create XML
		$xmlWriter = New-Object System.XMl.XmlTextWriter("$PSScriptRoot\ScriptConfig.XML", $null)
		$xmlWriter.Formatting = 'Indented'
		$xmlWriter.Indentation = 1
		$XmlWriter.IndentChar = "`t"
		
		$xmlWriter.WriteStartDocument()
		
		$xmlWriter.WriteStartElement("Configuration") # Configuration Startnode
		$xmlWriter.WriteElementString("ConfigVersion", "$checkVersionConfig")
		$xmlWriter.WriteElementString("CustomerBigram", "$BigramXML")
		$xmlWriter.WriteElementString("DBscriptPath", "D:\Visma")
		$xmlWriter.WriteElementString("ReleaseVersion", "$ReleaseVersionXML")
		$xmlWriter.WriteElementString("PPP", "$PPPXML")
		$xmlWriter.WriteElementString("PFH", "$PFHXML")
		$xmlWriter.WriteElementString("PUD", "$PUDXML")
		$xmlWriter.WriteEndElement() # Configuration endnode
		$xmlWriter.Flush()
		$xmlWriter.Close()
		
		
		[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"
		
		$ConfigVersion = $xmlfile.configuration.ConfigVersion
		$BigramXML = $xmlfile.configuration.customerbigram
		$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
		$ReleaseVersionXML = $xmlfile.configuration.ReleaseVersion
		$PPPXML = $xmlfile.configuration.PPP
		$PUDXML = $xmlfile.configuration.PUD
		$PFHXML = $xmlfile.configuration.PFH
		
		
		Write-host "CustomerBigram: $BigramXML"
		Write-Host "ReleaseVersion: $ReleaseVersionXML"
		Write-host "SQL-verison PPP:$PPPXML"
		Write-host "SQL-verison PUD:$PUDXML"
		Write-host "SQL-verison PFH:$PFHXML"
		
		Add-Type -AssemblyName PresentationCore, PresentationFramework
		$ButtonType = [System.Windows.MessageBoxButton]::Ok
		$MessageIcon = [System.Windows.MessageBoxImage]::Information
		$MessageBody = "You need to run the commmand again after you updated the versionnumbers"
		$MessageTitle = "Rerun your command"
		
		$Result = [System.Windows.MessageBox]::Show($MessageBody, $MessageTitle, $ButtonType, $MessageIcon)
		
		
		exit
	}
	
	
}




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


# Todays date (used with backupfolder and Pre-Check txt file
$Today = (get-date -Format yyyyMMdd)
$Time = (get-date -Format HH:MM:ss)

# Services to check
$services = "Scheduler", "Ciceron Server Manager", "NeptuneMB_$BigramXML", "PersonecPBatchManager$BigramXML", "PersonecPUtdataExportImportService$BigramXML", "RSPFlexService$BigramXML", "Visma.P-Background-Service - $BigramXML", "Visma.PersonecP.PufIa.WinSvc - $BigramXML"
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

function New-RandomPassword
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
			$copied = ($Files[0 .. ($Files.Length - 2)] | ForEach-Object{ $_.Split("`t")[-2] } | Measure-Object -sum).Sum
			if ($LogData[-1] -match "(100|\d?\d\.\d)\%")
			{
				write-progress Copy -ParentID $RoboRun.ID -percentComplete $LogData[-1].Trim("% `t") $LogData[-1]
				$Copied += $Files[-1].Split("`t")[-2] /100 * ($LogData[-1].Trim("% `t"))
			}
			else
			{
				write-progress Copy -ParentID $RoboRun.ID -Completed
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
	
	
	$passwordGenerate = New-RandomPassword -length 12
	
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
	
	[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"
	
	$ConfigVersion = $xmlfile.configuration.ConfigVersion
	$BigramXML = $xmlfile.configuration.customerbigram
	$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
	$ReleaseVersionXML = $xmlfile.configuration.ReleaseVersion
	$PPPXML = $xmlfile.configuration.PPP
	$PUDXML = $xmlfile.configuration.PUD
	$PFHXML = $xmlfile.configuration.PFH
	
	
	
	# Check if backupfolder exist
	$folder = (test-path -Path "D:\visma\Install\Backup\$Today\")
	
	if ($folder -eq $false)
	{
		New-Item -Path "d:\visma\install\backup\" -ItemType Directory -Name $Today
	}
	
	# Inventory services and status
	foreach ($Service in $Services)
	{
		$InfoOnService = Get-CimInstance win32_service  | Where-Object Name -eq $Service | Select-Object name, startname, state, Startmode -ErrorAction SilentlyContinue
		
		$object = New-Object -TypeName PSObject
		$object | Add-Member -MemberType NoteProperty -Name 'Service' -Value $InfoOnService.name
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
	
	[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"
	
	$ConfigVersion = $xmlfile.configuration.ConfigVersion
	$BigramXML = $xmlfile.configuration.customerbigram
	$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
	$ReleaseVersionXML = $xmlfile.configuration.ReleaseVersion
	$PPPXML = $xmlfile.configuration.PPP
	$PUDXML = $xmlfile.configuration.PUD
	$PFHXML = $xmlfile.configuration.PFH
	
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
		write-host "No web.config for befolkning in backup fÃ¶r AG web.config"
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
	
	[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"
	
	$ConfigVersion = $xmlfile.configuration.ConfigVersion
	$BigramXML = $xmlfile.configuration.customerbigram
	$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
	$ReleaseVersionXML = $xmlfile.configuration.ReleaseVersion
	$PPPXML = $xmlfile.configuration.PPP
	$PUDXML = $xmlfile.configuration.PUD
	$PFHXML = $xmlfile.configuration.PFH
	
	
	$data5 = @()
	
	
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

#endregion

#region backup


# Copy to backup
if ($Backup -eq $true)
{
	
	
	Copy-ItemWithProgress D:\Visma\Wwwroot\ D:\Visma\Install\backup\$Today\wwwroot\ /e /xf *.log, *.svclog, Scheduler.txt* -ErrorAction SilentlyContinue
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
	Write-Host -ForegroundColor Yellow "The Site $bigramtoXML is stopped!"
	
	foreach ($Service in $Services)
	{
		Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue -Verbose
		Write-Host -ForegroundColor Yellow "$Service is Stopped!"
		
	}
	
}
#endregion

#region SQLQueries

if ($SqlQueries -eq $true)
{
	
	if (Test-Path "$PSScriptRoot\$today\SQL_queries.txt")
	{
		
		Remove-Item "$PSScriptRoot\$today\SQL_queries.txt"
		
	}
	
	[XML]$xmlfile = Get-Content "$PSScriptRoot\ScriptConfig.XML"
	
	$ConfigVersion = $xmlfile.configuration.ConfigVersion
	$BigramXML = $xmlfile.configuration.customerbigram
	$dbscriptpathXML = $xmlfile.configuration.dbscriptpath
	$PPPXML = $xmlfile.configuration.PPP
	$PUDXML = $xmlfile.configuration.PUD
	$PFHXML = $xmlfile.configuration.PFH
	
	
	
	$QRReadPW = New-RandomPassword -length 14
	
	$SQL_queries = @"
#------------------------------------------------#
# SQL Query for update scripts
#------------------------------------------------#

##Personic P
USE $DB_PPP
SELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\mRSPu$PPPXML.sql
GO
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\mRSPview.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\mRSPproc.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\mRSPtriggers.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\mRSPgra.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\msDBUPDATERIGHTSP.sql
:r d:\visma\Install\HRM\PPP\DatabaseServer\Script\SW\$ReleaseVersionXML\PPPds_Feltexter.sql
GO
SELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc
#------------------------------------------------#
#Personic U
USE $DB_PUD
SELECT * FROM dbo.PU_VERSIONSINFO
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSUu$PUDXML.sql
GO
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSUproc.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSUview.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSUgra.sql
:r d:\visma\Install\HRM\PUD\DatabaseServer\Script\SW\$ReleaseVersionXML\msdbupdaterightsU.sql
GO
SELECT * FROM dbo.PU_VERSIONSINFO
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc
#------------------------------------------------#
##Personic PFH
USE $DB_PFH
SELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSFu$PFHXML.sql
GO
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSFproc.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSFview.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$ReleaseVersionXML\mPSFgra.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$ReleaseVersionXML\msDBUPDATERIGHTSF.sql
:r d:\visma\Install\HRM\PFH\DatabaseServer\Script\SW\$ReleaseVersionXML\PFHds_Feltexter.sql
GO
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

USE [$DB_PFH] -- Personec FÃ¶rhandling
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

USE [$DB_PAG] -- Personec AnstÃ¤llningsguide
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
	
	$cred = Get-Credential -Message 'The Viwinstallpasswword please...' -UserName viwinstall
	Add-Type -AssemblyName Microsoft.VisualBasic
	$instans = [Microsoft.VisualBasic.Interaction]::InputBox("Vilken SQLinstans ska kollas?", "Skriv in sqlinstans", "localhost")
	$backupplats = [Microsoft.VisualBasic.Interaction]::InputBox("Vart ska backuperna sparas?", "Skriv in annan sÃ¶kvÃ¤g vid behov", "d:\visma")
	
	get-dbaDatabase -SqlInstance $instans -SqlCredential $cred | Select-Object -Property name, size -ExpandProperty name | Where-Object name -like '*$BigramXML*' | Out-GridView -PassThru -Title 'VÃ¤lj de databaser du vill ha backup pÃ¥ (markera flera med att hÃ¥lla ner CTRL' | ForEach-Object { Backup-DbaDatabase -SqlCredential $cred -SqlInstance $instans -Database $_ -CopyOnly -FilePath $backupplats -Verbose }
	
	
}

#endregion

#region CertRights

#Certrights
if ($Certrights -eq $true)
{
	
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
	function Set-PermissionCertificate
	{
		
		$Certificate = Get-ChildItem Cert:\LocalMachine\My | Out-GridView -Title 'Select cert' -PassThru
		
		$rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
		
		[string]$uniqueName = $rsaCert.key.UniqueName
		[string]$keyFilePath = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$uniqueName"
		$acl = Get-Acl -Path $keyFilePath
		
		$rule1 = new-object security.accesscontrol.filesystemaccessrule 'Visma Services Trusted Users', 'fullcontrol', allow
		
		$acl.AddAccessRule($rule1)
		Set-Acl -Path $keyFilePath -AclObject $acl
		
		$rule2 = new-object security.accesscontrol.filesystemaccessrule 'IIS_IUSRS', 'read', allow
		
		$acl.AddAccessRule($rule2)
		Set-Acl -Path $keyFilePath -AclObject $acl
		
	}
	Set-PermissionCertificate
	
	
}

#endregion

#region Thumbprint

#thumbprint
if ($certthumbprint -eq $true)
{
	# Define the starting date for the search
	$StartDate = Get-Date
	
	# Define the certificate path
	$CertPath = 'Cert:\LocalMachine\my'
	
	# Retrieve certificate details
	$CertsDetail = Get-ChildItem -Path $CertPath -Recurse | Where-Object {
		$_.PsIsContainer -ne $true
	} | ForEach-Object {
		# Calculate the number of days left until expiration
		$DaysLeft = (New-TimeSpan -Start $StartDate -End $_.NotAfter).Days
		# Format the expiration date
		$FinalDate = Get-Date $_.NotAfter -Format 'dd/MM/yyyy hh:mm'
		# Retrieve intended purposes
		$Usages = $_.Extensions | Where-Object {
			$_.Oid.FriendlyName -eq 'Enhanced Key Usage'
		} | ForEach-Object {
			$_.Format(0) -join ', '
		}
		# Create a custom object with the required details
		[PSCustomObject]@{
			Thumbprint	     = $_.Thumbprint
			Subject		     = $_.Subject
			ExpireDate	     = $FinalDate
			DaysRemaining    = $DaysLeft
			IntendedPurposes = $Usages
		}
	} | Out-GridView -PassThru
	
	$CertsDetail.thumbprint | Set-Clipboard
	
	#endregion
	
	
	
}
