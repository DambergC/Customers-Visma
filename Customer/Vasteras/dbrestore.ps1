# Install DBATools and dependencies
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

# Cred

$cred = Get-Credential -UserName viwinstall -Message 'viwinstallkontots pwd tack!'


# Read configfile for script

$file = 'D:\DBRestore.XML'
$xml = [XML](get-content $file)

$databasestest = $xml.Configuration.Test.Databases.Db
$databasesprod = $xml.Configuration.Prod.Databases.db
$restorepathMDF = $xml.Configuration.RestorePathMDF
$restorepathLOG = $xml.Configuration.RestorePathLOG
$bigramPROD = $xml.Configuration.Prod.Bigram
$bigramTEST = $xml.Configuration.Test.Bigram
$rspdbuser = $xml.Configuration.Test.Rspdbuser
$psutotint = $xml.Configuration.Test.Psutotint
$SQLPROD = $xml.Configuration.Prod.Sqlserver
$SQLTEST = $xml.Configuration.Test.Sqlserver
$backuppathTEST = $xml.Configuration.Test.Backuppath
$backuppathPROD = $xml.Configuration.Prod.BackuppathUNC
$importcatalog = $xml.Configuration.Test.Importcatalog
$exportcatalog = $xml.Configuration.test.Exportcatalog


$date = get-date -Format yyyyMMdd

# Backup of databases
foreach ($databaseP in $databasesprod)

{
    Write-host "Start backup of $databaseP" -ForegroundColor Green
    Backup-DbaDatabase -SqlInstance $SQLPROD -Database $databaseP -Path $backuppathTEST -Type Full -CopyOnly -Verify -TimeStampFormat yyyyMMdd -SqlCredential $cred
}



#Drop old databases

for($i = 0; $i -lt $databasestest.Length; $i++)
{

   $dbtest = $databasestest[$i]
    Write-host "Drop $dbtest from $SQLTEST" -ForegroundColor Green
    Remove-DbaDatabase -SqlInstance $SQLTEST -Database $dbtest -Confirm:$true -Verbose -SqlCredential $cred

}



#restore database and set logical filename to databasename

for($i = 0; $i -lt $databasestest.Length; $i++)
{
    
    $dbprod = $databasesprod[$i]
    $dbtest = $databasestest[$i]
    $Backupfilepath =@()
    $Backupfilepath = $backuppathtest
    $Backupfilepath += $dbprod
    $Backupfilepath += "_"
    $Backupfilepath += $date
    $Backupfilepath += ".bak"
    
    Write-host "Start restore of $dbtest from $Backupfilepath" -ForegroundColor Green

    Restore-DbaDatabase -SqlInstance $SQLTEST -DatabaseName $dbtest -Path $Backupfilepath -ReplaceDbNameInFile -DestinationLogDirectory $restorepathLOG -DestinationDataDirectory $restorepathMDF -WithReplace -Confirm:$true -SqlCredential $cred
    Rename-DbaDatabase -SqlInstance $SQLTEST -Database $dbtest -LogicalName $dbtest -Verbose -SqlCredential $cred


}

#Set database in simple mode and trucate only

for($i = 0; $i -lt $databasestest.Length; $i++)
{

    Set-DbaDbRecoveryModel -SqlInstance $SQLTEST -Database $dbtest -RecoveryModel Simple -Verbose -Confirm:$false -SqlCredential $cred
    Invoke-DbaDbShrink -SqlInstance $SQLTEST -Database $dbtest -ShrinkMethod TruncateOnly -Verbose -SqlCredential $cred
}

# Queries against db


# PPP
    $UsersDB =@()
    $UsersDB = $bigramTEST
    $UsersDB += "_"
    $UsersDB += "PPP"
write-host "Fixed users in $UsersDB" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "sp_change_users_login update_one,'$rspdbuser','$rspdbuser'" -Verbose -SqlCredential $cred
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "sp_change_users_login update_one,'$psutotint','$psutotint'" -Verbose -SqlCredential $cred
write-host "Removed registred jobs" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "delete from dbo.OA0P0920 where status=8080 or status=8081 or status=8082" -Verbose -SqlCredential $cred
write-host "Change import export catalogs" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "update dbo.oa0p0008 set IMPKAT= '$importcatalog'" -Verbose -SqlCredential $cred
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "update dbo.oa0p0008 set EXPKAT= '$exportcatalog'" -Verbose -SqlCredential $cred
write-host "Add TEST to all companies" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "update oa0p0054 SET IDTEXT = IDTEXT+' TEST' where len(strpos)=25 and LEN(IDTEXT)<24" -Verbose -SqlCredential $cred
write-host "Remove all scheduled jobs" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "update dbo.oa0p0024 set AUTOMATISK=0  where AUTOMATISK=1 and PERIODICITET>0" -Verbose -SqlCredential $cred

# PUD
    $UsersDB =@()
    $UsersDB = $bigramTEST
    $UsersDB += "_"
    $UsersDB += "PUD"
write-host "Fixed users in $UsersDB" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "sp_change_users_login update_one,'$rspdbuser','$rspdbuser'" -Verbose -SqlCredential $cred
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "sp_change_users_login update_one,'$psutotint','$psutotint'" -Verbose -SqlCredential $cred
write-host "Add TEST to every company in PSutdata" -ForegroundColor green
Invoke-DbaQuery -SqlInstance $SQLTEST -Database $UsersDB -Query "update dbo.ou0p0054 SET IDTEXT = IDTEXT+' TEST' where typ=1 " -Verbose -SqlCredential $cred





    
