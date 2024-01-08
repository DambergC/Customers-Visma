
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

#set singleuser

for($i = 0; $i -lt $databasestest.Length; $i++)
{

    $dbprod = $databasesprod[$i]
    $dbtest = $databasestest[$i]

    Set-DbaDbState -SqlInstance $SQLTEST -Database $dbtest -SingleUser
    Write-host "Setting $SQLTEST in single user" -ForegroundColor Green

}



#restore

$file = 'D:\DBRestore.XML'
$xml = [XML](get-content $file)

$databasestest = $xml.Configuration.DatabasesTest.db
$databasesprod = $xml.Configuration.DatabasesProd.db
$restorepathMDF = $xml.Configuration.RestorePathMDF
$restorepathLOG = $xml.Configuration.RestorePathLOG
 

for($i = 0; $i -lt $databasestest.Length; $i++)
{
    $Backupfilepath =@()
    $dbprod = $databasesprod[$i]
    $dbtest = $databasestest[$i]
    $Backupfilepath = $backuppath
    $Backupfilepath += $dbprod
    $Backupfilepath += "_"
    $Backupfilepath += $date
    $Backupfilepath += ".bak"

    $MDFfilepath =@()
    $MDFfilepath = $restorepathMDF
    #$MDFfilepath += $dbtest
    #$MDFfilepath += ".mdf"

    $LOGfilepath =@()
    $LOGfilepath = $restorepathLOG
    #$LOGfilepath += $dbtest
    #$LOGfilepath += ".log"
    
    Write-host "Start restore of $dbtest from $Backupfilepath" -ForegroundColor Green
    Write-host "$LOGfilepath $MDFfilepath" -ForegroundColor Green

    Restore-DbaDatabase -SqlInstance $SQLTEST -DatabaseName $dbtest -Path $path -ReplaceDbNameInFile -DestinationLogDirectory $restorepathLOG -DestinationDataDirectory $restorepathMDF -Confirm -WithReplace
}

