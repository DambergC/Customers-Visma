
if (Get-Module -Name dbatools)

{
    write-host 'Dbatools installed' -ForegroundColor Green
}

else

{
    Install-Module dbatools -Verbose -Force
    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -Register
    Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false -Register
}

$backuppath = 'D:\DBbackup\'
$SQLPROD = 'Localhost'
$SQLTEST = 'Localhost'


$file = 'D:\DBRestore.XML'
$xml = [XML](get-content $file)

$databasesprod = $xml.Configuration.DatabasesProd.db

foreach ($databaseP in $databasesprod)

{

    Write-host "Start backup of $databaseP" -ForegroundColor Green
    Backup-DbaDatabase -SqlInstance $SQLPROD -Database $databaseP -Path $backuppath -Type Full -CopyOnly -Verify -TimeStampFormat yyyyMMdd
    
}


$file = 'D:\DBRestore.XML'
$xml = [XML](get-content $file)

$databasestest = $xml.Configuration.DatabasesTest.db
$databasesprod = $xml.Configuration.DatabasesProd.db 

$date = get-date -Format yyyyMMdd

for($i = 0; $i -lt $databasestest.Length; $i++)
{

    $dbprod = $databasesprod[$i]
    $dbtest = $databasestest[$i]

    Write-host "Start restore of $dbtest from $backuppath$dbprod$date.bak" -ForegroundColor Green
    #Restore-DbaDatabase -SqlInstance $SQLTEST -DatabaseName $dbtest -Path "$backuppath$dbprod_$date.bak"
}

