$username = 'nano'
$password = 'P@ssw0rd'
$groupname = 'puppet'

exec { 'new-local-group':
    command => "New-LocalGroup -Name ${groupname}",
    unless => "Get-LocalGroup -Name ${groupname}",
    provider => powershell,
}

exec { 'new-local-user':
    command => "New-LocalUser -Name ${username} -Password \
(ConvertTo-SecureString -AsPlainText \"${password}\" -Force) \
-PasswordNeverExpires",
    unless => "Get-LocalUser -Name ${username}",
    provider => powershell,
}

exec { 'add-local-group-member':
    command => "Add-LocalGroupMember -Group ${groupname} -Member ${username}",
    unless => "Get-LocalGroupMember -Group ${groupname} -Member ${username}",
    provider => powershell,
    require => [Exec['new-local-group'], Exec['new-local-user']],
}
