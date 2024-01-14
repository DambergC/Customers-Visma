#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

#region Add-RichTextBox
# Function - Add Text to RichTextBox
function Add-RichTextBox
{
	[CmdletBinding()]
	param ($text)
	#$richtextbox_output.Text += "`tCOMPUTERNAME: $ComputerName`n"
	$richtextbox_output.Text += "$text`n"
	$richtextbox_output.Text += "- - - - - - - - - - - - - - -`n"
}
#Set-Alias artb Add-RichTextBox -Description "Add content to the RichTextBox"
#endregion


#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory



# Name of xmlfile
$xmlfile = "$ScriptDirectory\DBRestore.XML"