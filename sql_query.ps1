$bigram = "BIGRAM"
$long_version = 22040
$short_version = 2240
$script_path = "D:\Visma\Install\Backup"
$file_path = "D:\Visma\Install\Backup\SQL-query.txt"

$query = "
##Personic P

USE $bigram" + "_PPP
SELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997
:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\mRSPu$short_version.sql

:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\mRSPview.sql
:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\mRSPproc.sql
:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\mRSPtriggers.sql
:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\mRSPgra.sql
:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\msDBUPDATERIGHTSP.sql 
:r  $script_path\HRM\PPP\DatabaseServer\Script\SW\$long_version\PPPds_Feltexter.sql

SELECT DBVERSION, PROGVERSION FROM dbo.OA0P0997
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc


##Personic U
USE $bigram" + "_PUD
SELECT * FROM dbo.PU_VERSIONSINFO
:r  D:\Visma\Install\HRM\PUD\DatabaseServer\Script\SW\$long_version\mPSUu$short_version.sql

:r  D:\Visma\Install\HRM\PUD\DatabaseServer\Script\SW\$long_version\mPSUproc.sql
:r  D:\Visma\Install\HRM\PUD\DatabaseServer\Script\SW\$long_version\mPSUview.sql
:r  D:\Visma\Install\HRM\PUD\DatabaseServer\Script\SW\$long_version\mPSUgra.sql
:r  D:\Visma\Install\HRM\PUD\DatabaseServer\Script\SW\$long_version\msdbupdaterightsU.sql  

SELECT * FROM dbo.PU_VERSIONSINFO
SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc


##Personic PFH

USE $bigram" + "_PFH
SELECT DBVERSION, PROGVERSION FROM dbo.OF0P0997
:r D:\Visma\Install\HRM\PFH\DatabaseServer\Script\SW\$long_version\mPSFu$short_version.sql

:r D:\Visma\Install\HRM\PFH\DatabaseServer\Script\SW\$long_version\mPSFproc.sql
:r D:\Visma\Install\HRM\PFH\DatabaseServer\Script\SW\$long_version\mPSFview.sql
:r D:\Visma\Install\HRM\PFH\DatabaseServer\Script\SW\$long_version\mPSFgra.sql
:r D:\Visma\Install\HRM\PFH\DatabaseServer\Script\SW\$long_version\msDBUPDATERIGHTSF.sql
:r D:\Visma\Install\HRM\PFH\DatabaseServer\Script\SW\$long_version\PFHds_Feltexter.sql

SELECT * FROM dbo.RMRUNSCRIPT order by RUNDATETIME1 desc
"

Out-File -FilePath $file_path -Encoding Unicode -InputObject $query
