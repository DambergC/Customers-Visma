# vilket bigram har kunden
$bigram = 'Visma'

# Lista vilka db som finns kopplade till 
$database = Invoke-Sqlcmd -Username 'viwinstall' -Password 'W{JX3%2TrLS8Fr{8' -Query "SELECT name FROM sys.databases where name LIKE '$bigram%' order by name;" 

# lista servernamn och core
$core = Get-WmiObject –class Win32_processor 

# ta ut sql version
$sqlversion = Invoke-Sqlcmd -ServerInstance "localhost" -Username 'viwinstall' -Password 'W{JX3%2TrLS8Fr{8' -Query "SELECT
    SERVERPROPERTY('ProductVersion') AS BuildNumber,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('ProductUpdateLevel') AS UpdateLevel,
    SERVERPROPERTY('ProductUpdateReference') AS UpdateReference,
    SERVERPROPERTY('ProductMajorVersion') AS Major,
    SERVERPROPERTY('ProductMinorVersion') AS Minor,
    SERVERPROPERTY('ProductBuild') AS Build"




$core.PSComputerName
$core.NumberOfCores
$core.NumberOfLogicalProcessors
