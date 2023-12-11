
# Array to save data
$data = @()

$BigramXML = 'visma'


$services = "Scheduler", "Ciceron Server Manager", "NeptuneMB_$BigramXML", "PersonecPBatchManager$BigramXML", "PersonecPUtdataExportImportService$BigramXML", "RSPFlexService$BigramXML"

foreach ($service in $services)
{

$Getdata = Get-CimInstance -class win32_service -Filter "name='$service'" | Select-Object name, state, Startmode, startname
$data += $Getdata

}

$xmlData = @()
$xmlData += '<?xml version="1.0" encoding="UTF-8"?> '
$xmlData += '<services>'
foreach ($obj in $data) 
{
    $properties = $data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty  Name

    $xmlData += '   <service>'
    foreach ($property in $properties) 
    {
        $xmlData += "       <$property>$($obj.$property)</$property>"
    }
    $xmlData += '   </service>'
}
$xmlData += '</services>'
$xmlData | Out-File -FilePath d:\file.xml
