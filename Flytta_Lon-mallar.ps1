$BIGRAM = "VAEENK"
$Today = (get-date -Format yyyyMMdd)

Remove-Item -Path "D:\Visma\wwwroot\$BIGRAM\PPP\Personec_P_web\Lon\cr\rpt\*"
Remove-Item -Path "D:\Visma\wwwroot\$BIGRAM\PPP\Personec_AG\CR\rpt\*"
Write-Output("Robocopy D:\Visma\Install\Backup\$Today\wwwroot\$BIGRAM\PPP\Personec_P_web\Lon\cr\rpt D:\Visma\wwwroot\$BIGRAM\PPP\Personec_P_web\Lon\cr\rpt")
Write-Output("Robocopy D:\Visma\Install\Backup\$Today\wwwroot\$BIGRAM\PPP\Personec_AG\CR\rpt D:\Visma\wwwroot\$BIGRAM\PPP\Personec_AG\CR\rpt")