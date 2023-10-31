<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-PermissionCertificate
{

    	$Certificate = Get-ChildItem Cert:\LocalMachine\My | Out-GridView -Title 'Select cert' -PassThru

        $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)

        [string] $uniqueName = $rsaCert.key.UniqueName
        [string] $keyFilePath = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$uniqueName"
        $acl = Get-Acl -Path $keyFilePath
        
        $rule1 = new-object security.accesscontrol.filesystemaccessrule 'Visma Services Trusted Users', 'fullcontrol', allow
               
        $acl.AddAccessRule($rule1)
        Set-Acl -Path $keyFilePath -AclObject $acl

        $rule2 = new-object security.accesscontrol.filesystemaccessrule 'IIS_IUSRS', 'read', allow
               
        $acl.AddAccessRule($rule2)
        Set-Acl -Path $keyFilePath -AclObject $acl

}
Set-PermissionCertificate
