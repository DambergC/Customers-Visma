﻿#------------------------------------------------------------------------
# Source File Information (DO NOT MODIFY)
# Source ID: 9412a787-8f13-4a73-b7eb-0451e23b0204
# Source File: Demo-LOadXML.pff
#------------------------------------------------------------------------
#region File Recovery Data (DO NOT MODIFY)
<#RecoveryData:
GBEAAB+LCAAAAAAABADsvQdgHEmWJSYvbcp7f0r1StfgdKEIgGATJNiQQBDswYjN5pLsHWlHIymr
KoHKZVZlXWYWQMztnbz33nvvvffee++997o7nU4n99//P1xmZAFs9s5K2smeIYCqyB8/fnwfPyIe
v8qn1WVeXz/N2uzoN07S9PGXdXFRLLPyWVHmL7JFfvQ0X1Tbz7/MZr/3F8/Hq/Pzx3d7TfhF/PWT
ed0U1fJod7z3+K7/gYCe/HQ+bdP2epV/9tHr66bNF+PvFstZddWMn1X1Qv4dpbGvRqmC+mx/vIP/
RunJumzXdf7ZMl+3dVaO0pfrSVlMf6/8+k31Nl9+NnnwILs/vf/p7sN7+/nOwcOP0iUh+9lH5wRv
96N0Oi/KWU3tPjqplm1dlc1HjCYh+rKuVnndXusLx9NpvmqfrNu2Wpo21OpVfp7T+9Ncm024wZe/
10fpXQPoroE0APmkLPJl+7r4Qf7R0ae790bp/qd7N74Eejyp6llev26vS3rzWfEunz0tsrK6uPHl
L7J3xYL6e1K9oxezsslvfqVYvu8r4IqPjpjQN7Z93WZ1+7JqirYAeU+IIDSyaZ3nyxvffZO/awkn
6qff9PSSIGm751U2k3b86e+Pvx/f5d9N85uZEzLyeV3MftYZdEYdXVBHG5m0Twzg90W+mOS116ZL
lv5r384zYiUaQ35SlRW9qz2Btrd4/Xk1zWTmdvdG6d7+LV4R7rCjvMUbIiH3Dx6O0nu7fQmJMEY2
OVvOcmLYCAPelbm+/cyL6P+sz7tTIO8z7cfL6RzT9qSit0l7viou5reZOFEYr/KGsP3o6Mvf6xav
uLm+v/cpKau9B7d4SWbbjO0WL8hkP7hP3HTvFs3dVO/cpjVrjFvh8VWT/2TRrLOS1eyTbPpWBeRN
vY6oQJ+rwj+Om4bEklR9Y9rqJ9dHi2Za1WUx+Qa46PFdC7Xby88S3/7MyaPf97tnL55++d3Xv+8X
xbSumuq8Hb84ffP7PquJgldV/fb3vQT0ezv3dh/+vlHRmpXlzYg/rbOrYnnxdVDeuXd+//zB+e7u
7P5Odi/7eihr/7dD9otsmV3kCzIt4+M1SSRLjEN997ao39udnN87uP9pNrv36X5+7/6NPbs+9m7b
x9eaUUC/v/Ng74Ehz63IAuv0c4YhOr8dmr/3ovw5wxIO9q2QfFrUpFyq+vp1Xl8W09wT5tuj/HUk
o0/YLia3G8AJeRsO53vj+7fEuUvm6aPfl9TwBSGYItpofl/nkzul64bjD4U6NYMANjfg7SgiJuFJ
1hRTT6h3flbJ7hRSFI8I7vZPY3QevyT7RXqpNkP7PF/mhKBn/aSBDejEqEU/1Q/PphrZBU3DT0kb
Fud5057UOStC+GO9z2zrk3VDGtN878Ee+uJlmbUIM4624eeZP+zXr9bL12+O4Rjob+7F6oqijHle
liZEhVvZ+9DY9pBaj1/n03VdkKdgI73whbQbDjN39ENiQaWuZutp22vc+bzbvjtRsU+f5s20LlYh
ke9GPz2pFqtseU3hflNcLPOZOrtN+guzxeowNfJNU6ENvTdX1zWcTn+++p+dIa6jrEEH7/jH0RSD
vDD8FWG2cBGdoOF/8vhukI4wDAuRIAbxMyH/TwAAAP//3DrsQBgRAAA=#>
#endregion
#========================================================================
# Code Generated By: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.17
# Generated On: 3/27/2013 6:24 PM
# Generated By: James Vierra
# Organization: Designed Systems & Services
#========================================================================
#----------------------------------------------
#region Application Functions
#----------------------------------------------

function OnApplicationLoad {
	#Note: This function is not called in Projects
	#Note: This function runs before the form is created
	#Note: To get the script directory in the Packager use: Split-Path $hostinvocation.MyCommand.path
	#Note: To get the console output in the Packager (Windows Mode) use: $ConsoleOutput (Type: System.Collections.ArrayList)
	#Important: Form controls cannot be accessed in this function
	#TODO: Add snapins and custom code to validate the application load
	
	return $true #return true for success or false for failure
}

function OnApplicationExit {
	#Note: This function is not called in Projects
	#Note: This function runs after the form is closed
	#TODO: Add custom code to clean up and unload snapins when the application exits
	
	$script:ExitCode = 0 #Set the exit code for the Packager
}

#endregion Application Functions

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Call-Demo-LOadXML_pff {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("Microsoft.VisualBasic, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form1 = New-Object 'System.Windows.Forms.Form'
	$datagrid1 = New-Object 'System.Windows.Forms.DataGrid'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	
	
	
	
	
	
	$FormEvent_Load={
		#TODO: Initialize Form Controls here
	$xml=[xml]@'
<watch_folders>
  <check_interval>5</check_interval>
  <multithread>0</multithread>
  <watch_folder_pair>
    <error_properties>C:\Program Files (x86)\something\comp_props.dat</error_properties>
    <log_file>C:\Program Files (x86)\something\watchedfolder.log</log_file>
    <processed_action>delete</processed_action>
    <processed_parameter></processed_parameter>
    <error>\\share\Barcodes\Error</error>
    <recursive>0</recursive>
    <file_extensions>tif;tiff;jpg;jpeg;pdf;</file_extensions>
    <in>\\share\Import</in>
    <out>\\share\Export</out>
    <command>"C:\Program Files (x86)\something\something.exe" -globaloff -m 1 -c ON -qualityc 20 -qualityg 20 -rscdwndpi 300 -rscinterp smartbicubic -rsgdwndpi 300 -rsginterp smartbicubic -rsbdwndpi 300 -rsbinterp smartbicubic -cconc -ccong -redirstderr -config "C:\ProgramData\something\ImgProc.xml" -annotation "C:\Scanning\Cover.xml" -in "/%in/" -out "/%out/.pdf"</command>
  </watch_folder_pair>
</watch_folders>
'@
	     $list=$xml.watch_folders.watch_folder_pair |
	          ForEach-Object{
	               New-Object PsObject -Property @{
	                                                  IN=$_.in;
	                                                  OUT=$_.out;
	                                                  ERROR=$_.error
	                                             }
	          }
	     $array = New-Object System.Collections.ArrayList     
	     $array.AddRange([array]$list)     
	     $datagrid1.DataSource=$array 
	}
	
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$form1.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$form1.remove_Load($FormEvent_Load)
			$form1.remove_Load($Form_StateCorrection_Load)
			$form1.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	#
	# form1
	#
	$form1.Controls.Add($datagrid1)
	$form1.Controls.Add($buttonOK)
	$form1.AcceptButton = $buttonOK
	$form1.ClientSize = '613, 462'
	$form1.FormBorderStyle = 'FixedDialog'
	$form1.MaximizeBox = $False
	$form1.MinimizeBox = $False
	$form1.Name = "form1"
	$form1.StartPosition = 'CenterScreen'
	$form1.Text = "Form"
	$form1.add_Load($FormEvent_Load)
	#
	# datagrid1
	#
	$datagrid1.DataMember = ""
	$datagrid1.HeaderForeColor = 'ControlText'
	$datagrid1.Location = '12, 24'
	$datagrid1.Name = "datagrid1"
	$datagrid1.Size = '589, 312'
	$datagrid1.TabIndex = 1
	#
	# buttonOK
	#
	$buttonOK.Anchor = 'Bottom, Right'
	$buttonOK.DialogResult = 'OK'
	$buttonOK.Location = '526, 427'
	$buttonOK.Name = "buttonOK"
	$buttonOK.Size = '75, 23'
	$buttonOK.TabIndex = 0
	$buttonOK.Text = "OK"
	$buttonOK.UseVisualStyleBackColor = $True
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $form1.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$form1.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$form1.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $form1.ShowDialog()

} #End Function

#Call OnApplicationLoad to initialize
if((OnApplicationLoad) -eq $true)
{
	#Call the form
	Call-Demo-LOadXML_pff | Out-Null
	#Perform cleanup
	OnApplicationExit
}

# SIG # Begin signature block
# MIIOzAYJKoZIhvcNAQcCoIIOvTCCDrkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUslRwcyo+RxQ+BG703v+ipJWl
# Zq2gggpWMIICAjCCAWugAwIBAgIQrxaY7pyfbb9IizLsigjxSTANBgkqhkiG9w0B
# AQUFADARMQ8wDQYDVQQDEwZERVZXUzIwHhcNMTIwMTAxMDQwMDAwWhcNMTgwMTAx
# MDQwMDAwWjARMQ8wDQYDVQQDEwZERVZXUzIwgZ8wDQYJKoZIhvcNAQEBBQADgY0A
# MIGJAoGBANd3vLHfse+6Tq9DMJoaYuZ/AuZjEEa11NghkHImir7O+N1QcL+UGNGv
# BI0SAVv3XtP/SwYPIj2Akkh2wLZlAI4QZd87RwJYBB6IsGfv4Ig7iJjK2u5+X8Ei
# aG7r/VPLhkiOCxQInd67gknjnUslI1Y8xVkdf1Isjs0qvl9DhRlDAgMBAAGjWzBZ
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMEIGA1UdAQQ7MDmAEONf5GFGBG6X3U7xJNuS
# MmGhEzARMQ8wDQYDVQQDEwZERVZXUzKCEK8WmO6cn22/SIsy7IoI8UkwDQYJKoZI
# hvcNAQEFBQADgYEA06r7xw/Vdo8KH1U/JjPtzh4JK3sQWkYp805S0HxjxnsX9RhW
# gQHJLr5icz++k92iFFOVRAxhaPRXs2fyrY1if5p3mEmnFbhax/NW9J+2UmmhZg32
# BAGvymAGUUmmTrYWS2rQhYLm09q4C5B0iYpTN4fhyEH3gljZGf9PdfvaUWcwggQa
# MIIDAqADAgECAgsEAAAAAAEgGcGQZjANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQG
# EwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEQMA4GA1UECxMHUm9vdCBD
# QTEbMBkGA1UEAxMSR2xvYmFsU2lnbiBSb290IENBMB4XDTA5MDMxODExMDAwMFoX
# DTI4MDEyODEyMDAwMFowVDEYMBYGA1UECxMPVGltZXN0YW1waW5nIENBMRMwEQYD
# VQQKEwpHbG9iYWxTaWduMSMwIQYDVQQDExpHbG9iYWxTaWduIFRpbWVzdGFtcGlu
# ZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMMMtxINTWiKM942
# BfA8uvXazQ5Te0afgvJiE9fBd627gTd+Tx6TgcEGItodUITGl5WSqZO2PauGeRlU
# fQ4WBEzEiJcsxqGoXxU60mQrzD4MeuikVrEeu8+Ezo01OjScbC3Ad7UwqR9n5joJ
# RDpDckGikcNGmh+2uacPrxx1G2Ql5whsFEf1RxrejuqiY5V99aitVaJkm3JvuQJz
# PzmKOVzE/o/7EZy9EBlJY9BDIovWq5KZdBTPMAe+T739io+eWt9tPMxamVCQua3C
# l0PCX+3NMz2HzMGgW6liO3h9ZKOsTR8r1wMRbHFUirCrsRzWfSPbQAc3JttQrzg9
# pgd1b5cCAwEAAaOB6TCB5jAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHQ4EFgQU6MLxxDLcMzU3vGV29ZwXLhdFLP4wSwYDVR0gBEQwQjBA
# BgkrBgEEAaAyAR4wMzAxBggrBgEFBQcCARYlaHR0cDovL3d3dy5nbG9iYWxzaWdu
# Lm5ldC9yZXBvc2l0b3J5LzAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8vY3JsLmds
# b2JhbHNpZ24ubmV0L3Jvb3QuY3JsMB8GA1UdIwQYMBaAFGB7ZhpFDZfKiVAvfQTN
# NKj//P1LMA0GCSqGSIb3DQEBBQUAA4IBAQBd9ssrDQFAhJ+FekNwauDF56oGANdn
# E8kIkTFlTxSoqQXcOJ5qoDAKvY3HgCjuQkXKlPPeWEWpgDIE9VlcanAAOSeUTfW0
# RjToHFMxsrNUFunMQqvV2VkwHPtGJyW4hyOx6HWIJIMeyHY3ewFJRUik7eJd0nyc
# otwtuhBaEmJlq64AxxA0O8tyvRQkDNzDdie0p/7hWCnyDhafkTkdiabmDxyHjOJY
# rJJ+JD6q7BTnOjM0i8Y7rIOrDxRieroaLU1LG8Uw8AuSeX08eOD45tIVllmZOSsw
# Yei4+MCh6SIUEXh9xNyJvsC7lOFyruu1QEBP7xceWF7QqImWrJIo6bq/MIIELjCC
# AxagAwIBAgILAQAAAAABJbC0zAEwDQYJKoZIhvcNAQEFBQAwVDEYMBYGA1UECxMP
# VGltZXN0YW1waW5nIENBMRMwEQYDVQQKEwpHbG9iYWxTaWduMSMwIQYDVQQDExpH
# bG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQTAeFw0wOTEyMjEwOTMyNTZaFw0yMDEy
# MjIwOTMyNTZaMFIxCzAJBgNVBAYTAkJFMRYwFAYDVQQKEw1HbG9iYWxTaWduIE5W
# MSswKQYDVQQDEyJHbG9iYWxTaWduIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzcI9XXci0MJ9ODLDFYMfQmo7
# U2bdajZEDWnPaI2JRZ9+L+5COjN8PgDTl2rYWtXDTZIKXwZQ/b9sxAOigmDY7VIu
# E3Tel8ZFIXtV9uqxZAP8dGuyX8dsbEMUiiQQN0mVgdJIEqWidklQIX/KhXMKPF21
# Lq2Qql5NMssXk9l/lsDAiWVW2cWxP5gbJ/pJ7h0bywaMMBw7xadwW6irGFr+yPaO
# vwFdj2GYNA9YUf/fMupUZRwUK2z8DJAZZ+2b2dpjm9ZaJKN0jggjAKGStR4L0Qig
# Zn+SG6PtgGQCSY+2hO/RVY5eqZdaxQgCiJRWv5LrKi0GNZK1NzYx7MP+ejvChQID
# AQABo4IBATCB/jAfBgNVHSMEGDAWgBTowvHEMtwzNTe8ZXb1nBcuF0Us/jA8BgNV
# HR8ENTAzMDGgL6AthitodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L1RpbWVzdGFt
# cGluZzEuY3JsMB0GA1UdDgQWBBSqqqaK76Rkc9aV4nnIj+rPpWApyjAJBgNVHRME
# AjAAMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBLBgNV
# HSAERDBCMEAGCSsGAQQBoDIBHjAzMDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmds
# b2JhbHNpZ24ubmV0L3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBBQUAA4IBAQC8iez+
# 5jZVk1x51BF6hoCPF7aTsm2bkaFWGBHGVer2CO2tm571K4HIu91gextHmR5tQD4d
# gMIT1Y4EBS/b565SnmiEcqHlSmA8+JvVL0bYw7K3k1Osm2xDJCTR8fzpVi40EVgY
# Q+rv/zR0bKDAbH+tAxlpiB6VYMq7vQy7du/HJLCBxjgxzzatDDi4kCCEmy6PKLmf
# 9sqUJ82sOWFX4OOVWpx2kjD13qaXPXIcKmAyqDNNhjUzilzzpP33Bizha0sw9cvT
# Q2L4QbnefSDLBYyOLPZfNf0zjUKJZQg2LKOJ9FqFi7C5e9tsy6H40g4bu5d80Sd5
# vp18O+anVjTYyZGpMYID4DCCA9wCAQEwJTARMQ8wDQYDVQQDEwZERVZXUzICEK8W
# mO6cn22/SIsy7IoI8UkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCAsFkLFWaHEit41HTV3FHWo
# ROIdMA0GCSqGSIb3DQEBAQUABIGAfvLUg47642hXYSagXjqEwvdkxMdyaVs80Qdo
# ctO5sbdkktO8qXkvlUte/twxnkgIo/zM3XlGGuaBPUOCleIlBcws9dQrYBxVUzRL
# QH/kBc/ENWAKMfL1R1TGWmC9g6SucpXXYxVw6CxfOGBhsHk7flxEfHx1JI9YF8Q0
# TU2cbj2hggKXMIICkwYJKoZIhvcNAQkGMYIChDCCAoACAQEwYzBUMRgwFgYDVQQL
# Ew9UaW1lc3RhbXBpbmcgQ0ExEzARBgNVBAoTCkdsb2JhbFNpZ24xIzAhBgNVBAMT
# Gkdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBAgsBAAAAAAElsLTMATAJBgUrDgMC
# GgUAoIH3MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTEzMDMyNzIyMjM1M1owIwYJKoZIhvcNAQkEMRYEFLn+03bYgQQgcwVCxxzCsn5c
# 9WTDMIGXBgsqhkiG9w0BCRACDDGBhzCBhDCBgTB/BBSu3333a7okENZ9uvGPW6Fb
# QX5JbDBnMFikVjBUMRgwFgYDVQQLEw9UaW1lc3RhbXBpbmcgQ0ExEzARBgNVBAoT
# Ckdsb2JhbFNpZ24xIzAhBgNVBAMTGkdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENB
# AgsBAAAAAAElsLTMATANBgkqhkiG9w0BAQEFAASCAQBcxgfjtkDE/cBJlV9AfN18
# xFcZQbxbthoGJmOXUKw8w0g9WRCdqehc5hjgu15tm+Mw3rFCjN1KVA361ArUgNYR
# 61jsSifTRHJkxTzLGRgu1zNJFzC/Ys+i7gYjk18SfnTj3A/1P762m530Kln5mBUk
# lBwKdfr6Y1r1zdCFjy5cxCX2XiVRdPfXKhdIEzermeHfecbzQhIhyP/upMgU2AYH
# giZLTt+XqKnNzTjW1rrX9NVfxzN2tR7Ou0UEAyPugLyLYzhksVBcTtHTFrv+nLwG
# fTOZ4WmQ2XpV5//l4hNcKeS9zAWP6FowugAdstAGutmMcsfKWFQiiLfvIcZl4ydc
# SIG # End signature block