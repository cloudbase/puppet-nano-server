$djoin_share = 'djoin_blobs'
$djoin_share_dir = "c:\\${djoin_share}"
$djoin_share_node = 'addc1tp5.cloudbase.demo'
$addc_ip = '10.14.0.188'
$djoin_share_unc = "\\\\${djoin_share_node}\\${djoin_share}"
$djoin_user_name = "${djoin_share}"
$djoin_user_password = 'P@ssw0rd'

$nodes = ['nanotp5', 'node1', 'node2']

node 'nanotp5' {
  exec { 'set-dns':
    command => "Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses ${addc_ip}",
    unless => "if(!(Get-DnsClientServerAddress |? ServerAddresses -eq ${addc_ip})) { exit 1}",
    provider => powershell,
  }

  exec { 'map-djoin-share':
    command => "New-SmbMapping -RemotePath ${djoin_share_unc} -Username ${djoin_user_name} -Password \"${djoin_user_password}\"",
    unless => "Get-SmbMapping -RemotePath ${djoin_share_unc}",
    provider => powershell,
    require => Exec['set-dns'],
  }

  exec { 'check-djoin-blob':
     command => '$true',
     unless => "if(Test-Path ${djoin_share_unc}\\blob_${::fqdn}.txt) { exit 1 }",
     provider => powershell,
     require => Exec['map-djoin-share'],
  }

  exec { 'join-ad':
    command => "& djoin.exe /requestodj /loadfile ${djoin_share_unc}\\blob_\$ENV:ComputerName.txt /windowspath \$ENV:SystemRoot /localos; exit $lastexitcode",
    unless => "if(!(Get-CimInstance win32_computersystem).partofdomain -And (Test-Path ${djoin_share_unc}\\blob_\$ENV:ComputerName.txt)) { exit 1 }",
    provider => powershell,
    #path => 'c:\windows\system32',
    require => Exec['check-djoin-blob'],
    notify => Reboot['after-domain-join'],
  }

  reboot { 'after-domain-join':
    apply  => finished,
    timeout => 0,
  }
}

node $djoin_share_node {
  exec { 'create-ad-user':
    command => "New-ADUser -Name ${djoin_user_name} -AccountPassword (ConvertTo-SecureString -AsPlainText \"${djoin_user_password}\" -Force) -PasswordNeverExpires \$true -Enabled \$true",
    unless => "Get-ADUser -Identity ${djoin_user_name}",
    provider => powershell,
  }

  file { "${djoin_share_dir}":
     ensure => directory,
  }

  exec { 'create_djoin_share':
    command => "New-SmbShare -Name ${djoin_share} -Path ${djoin_share_dir} -ReadAccess ${djoin_user_name}",
    unless => "Get-SmbShare -Name ${djoin_share}",
    provider => powershell,
    require => [File["${djoin_share_dir}"], Exec['create-ad-user']],
  }

  $nodes.each |String $node| {
    exec { "djoin1_${node}":
      command => "djoin.exe /provision /domain cloudbase.demo /machine ${node} /savefile ${djoin_share_dir}\\blob_${node}.txt /reuse",
      path => 'c:\windows\system32',
      require => File["${djoin_share_dir}"],
      creates => "${djoin_share_dir}\\blob_${node}.txt",
    }
  }
}
