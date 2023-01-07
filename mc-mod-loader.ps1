#
#set execusion policy to unrestricted
#
$policy = Get-ExecutionPolicy 
if($policy -ne 'unrestricted'){
        Set-ExecutionPolicy unrestricted -Confirm:$false -Force
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
$ftp_path = 'path'  #path to mods folder on sftp server
$pass = ConvertTo-SecureString "password" -AsPlainText -Force   #sftp password
$login = "login"   #sftp login
$ftp_ip = "ip"   #server domainame or ip
#
#get the sftp connection
#
$session = New-SFTPSession -Computer $ftp_ip -Credential (New-Object System.Management.Automation.PSCredential -ArgumentList $login, $pass) -AcceptKey
#
#Synchronise mods from the server to host
#
if(Test-Path $mc_path\mods -PathType Container){    
    #if mods folder present get all installed mods
    $loc_mods = Get-ChildItem -Path $mc_path\mods   
    if($loc_mods){
        #if any mods are installed compare them to ones available on server
        $mods = Get-SFTPChildItem -SFTPSession $session -Path $ftp_path -File
        $diffs = Compare-Object -ReferenceObject $mods -DifferenceObject $loc_mods -Property Name
        $diffs | foreach{
            $f_name = $_.Name
            if($_.SideIndicator -eq '<='){
                #if mod is not present on host download it
                Get-SFTPItem -SFTPSession $session -Path $ftp_path/$f_name -Destination $mc_path\mods
            }
            elseif($_.SideIndicator -eq '=>'){
                #if mod on the host is not on the server remove it
                Remove-Item -Path $mc_path\mods\$f_name
            }
        }
    }
    else{
        #if mods folder empty, remove it and download one from the server
        Remove-Item -Path $mc_path\mods
        Get-SFTPItem -SFTPSession $session -Path $ftp_path -Destination $mc_path
    }
}
else{
    #if mods folder does not exits download one from the server
    Get-SFTPItem -SFTPSession $session -Path $ftp_path -Destination $mc_path
}
#
#Cleanup and launch minecraft
#
Remove-SFTPSession -SessionId $session.SessionId | Out-Null
Set-ExecutionPolicy $policy -Confirm:$false -Force
powershell -WindowStyle Hidden $mc_path\Tlauncher.exe