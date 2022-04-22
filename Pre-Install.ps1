#$bigram = read-host 'Bigram?'
$bigram = 'Visma'

# Todays date (used with backupfolder and Pre-Check txt file
$Today = (get-date -Format yyyyMMdd)

# Services to check
$services = "Ciceron Server Manager","PersonecPBatchManager","ersonec P utdata export Import Service","RSPFlexService"

# Array to save data
$data = @()

# Check and document services
foreach ($Service in $Services)
{
    $InfoOnService = Get-WmiObject Win32_Service | where Name -eq $Service | Select-Object name,startname,state,status
    $data += $InfoOnService
}

# Send data to file about services
$data | Out-File D:\visma\Install\Backup\Services_$Today.txt

# Check dotnet version installed and send to file
$dotnet = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where { $_.PSChildName -Match '^(?!S)\p{L}'} | Select PSChildName, version | Sort-Object version -Descending | Out-File D:\visma\Install\Backup\DetNet_$today.txt

# Copy to backup
#copy-item D:\visma\Programs -Destination D:\visma\Install\Backup\$today\Programs -Recurse -Exclude *.log -Verbose
#copy-item D:\visma\Wwwroot -Destination D:\visma\Install\Backup\$Today\Wwwroot -Recurse -Exclude *.log -Verbose

# Stop WWW site Bigram
Stop-IISSite -Name $bigram -Verbose


# Befolkningsregister Check
[XML]$Befolkningsregister = Get-Content "D:\visma\install\backup\$today\Wwwroot\$bigram\ppp\Personec_AG\Web.config"

$Befolkningsregister.configuration.appSettings.add | out-file d:\visma\install\backup\Befolkningsregister_$Today.txt

