#
#set execusion policy to unrestricted
#
$policy = Get-ExecutionPolicy 
if($policy -ne 'unrestricted'){
    try{
        Set-ExecutionPolicy unrestricted -Confirm:$false -Force
    }
    catch{"Run as an administrator !!!"}
}
#
#install and import required modules
#
if(!(Get-Module posh-ssh)){
    if(Get-Module -ListAvailable posh-ssh){
        Import-Module posh-ssh
    }
    else{
        Install-Module posh-ssh
        Import-Module posh-ssh
    }
}
# 
#variables for setting ftp user and paths
#
$mc_path = $env:USERPROFILE + '\AppData\Roaming\.minecraft'
$ftp_path = '/username/folder-mods'  #path to mods folder on sftp server
$pass = ConvertTo-SecureString "[password)$" -AsPlainText -Force   #sftp password
$login = "username"   #sftp login
$ftp_ip = 'ip-address'
#
#get the sftp connection
#
$session = New-SFTPSession -Computer $ftp_ip -Credential (New-Object System.Management.Automation.PSCredential -ArgumentList $login, $pass) -AcceptKey
#
#
#s
if(Test-Path $mc_path\mods -PathType Container){
    $loc_mods = Get-ChildItem -Path $mc_path\mods
    $mods = Get-SFTPChildItem -SFTPSession $session -Path $ftp_path -File
    if($loc_mods){
        $diffs = Compare-Object -ReferenceObject $mods -DifferenceObject $loc_mods -Property Name
        $diffs | foreach{
            $f_name = $_.Name
            if($_.SideIndicator -eq '<='){
                Get-SFTPItem -SFTPSession $session -Path $ftp_path/$f_name -Destination $mc_path\mods
            }
            elseif($_.SideIndicator -eq '=>'){
                Remove-Item -Path $mc_path\mods\$f_name
            }
        }
    }
    else{
        Remove-Item -Path $mc_path\mods
        Get-SFTPItem -SFTPSession $session -Path $ftp_path -Destination $mc_path
    }
}
else{
    Get-SFTPItem -SFTPSession $session -Path $ftp_path -Destination $mc_path
}
#
#Cleanup and launch minecraft
#
Remove-SFTPSession -SessionId $session.SessionId | Out-Null
Set-ExecutionPolicy $policy -Confirm:$false -Force
powershell -WindowStyle Hidden $mc_path\Tlauncher.exe