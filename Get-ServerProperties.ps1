×

<#
.Synopsis
   Script to inventory server for Visma application Personec P
.DESCRIPTION
   This script inventory the local server
   - Memory
   - Disksize
   - Databases
   - Sql version
   - OS Version
.EXAMPLE
   Get-ServerInventory -
.NOTES
   General notes
.FUNCTIONALITY
   The functionality that best describes this workflow
#>
function Get-ServerInventory
{
    Param
    (
        # Param1 help description
        [string]
        $Viwinstallpassword

    )

}

#dagens datum
$filename = get-date -Format yyyy-MM-dd

# server ip-adress
$ipadress = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $(Get-NetConnectionProfile | Select-Object -ExpandProperty InterfaceIndex) | Select-Object -ExpandProperty IPAddress


# vilket bigram har kunden
$bigram = 'DANYDK'

# Lista vilka db som finns kopplade till 
#$database = Invoke-Sqlcmd -Username 'viwinstall' -Password 'W{JX3%2TrLS8Fr{8' -Query "SELECT name FROM sys.databases where name LIKE '$bigram%' order by name;" 
$database = Invoke-Sqlcmd -Query "SELECT name FROM sys.databases where name LIKE '$bigram%' order by name;" 


# lista servernamn och core
$core = Get-WmiObject –class Win32_processor | Measure-Object -Property numberofcores -Sum
$countcpu = Get-WmiObject win32_processor

$test = $countcpu.count

# ta ut sql version
$sqlversion = Invoke-Sqlcmd -ServerInstance "localhost" -Query "SELECT
    SERVERPROPERTY('ProductVersion') AS BuildNumber,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('ProductUpdateLevel') AS UpdateLevel,
    SERVERPROPERTY('ProductUpdateReference') AS UpdateReference,
    SERVERPROPERTY('ProductMajorVersion') AS Major,
    SERVERPROPERTY('ProductMinorVersion') AS Minor,
    SERVERPROPERTY('ProductBuild') AS Build"

if ($sqlversion.major -eq '14')
{
    $sqlname = 'SQL Server 2017'
}

if ($sqlversion.major -eq '15')
{
    $sqlname = 'SQL Server 2019'
}

# Memory
$servermemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb


# Storageinventory
$logicalDisk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"|
    Select-Object DeviceID,
        @{ Name = "Size (GB)";       Expression = { "{0:N1}" -f ($_.size / 1GB) } }

       


    $output = [ordered]@{
        'ServerName'            = $env:COMPUTERNAME
        'OperatingSystem'       = (Get-CimInstance -ComputerName $server -ClassName Win32_OperatingSystem).Caption
        'IP-adress'             = $ipadress
        'SQL Server Version'    = $sqlname
        'Numbers of Core'       = $core.sum
        'Numbers of Processors' = $test
        'Memory (GB)'           = $servermemory
        }
    [pscustomobject]$output | Format-list | out-file d:\visma\install\backup\Serverinventory_$filename.txt
    
    
$logicalDisk | out-file d:\visma\install\backup\Serverinventory_$filename.txt -Append

$database | out-file d:\visma\install\backup\Serverinventory_$filename.txt -Append
Copy to Local Clipboard	Request Remote Clipboard	Copy to Remote Clipboard
Clear
