file { 'HttpPlatformHandler.dll':
    ensure => present,
    path => 'c:/Windows/System32/inetsrv/HttpPlatformHandler.dll',
    source => 'puppet:///extra_files/iis_demo/HttpPlatformHandler.dll',
  }

file { 'httpplatform_schema.xml':
    ensure => present,
    path => 'c:/Windows/System32/inetsrv/config/schema/httpplatform_schema.xml',
    source => 'puppet:///extra_files/iis_demo/httpplatform_schema.xml',
  }

file { 'c:\config_http_platform_handler.ps1':
    ensure => present,
    source => 'puppet:///extra_files/iis_demo/config_http_platform_handler.ps1',
  }
->
exec { 'config_http_platform_handler':
    command => 'c:\config_http_platform_handler.ps1',
    unless => 'Import-Module IISAdministration; if(Get-IISConfigSection "system.webServer/globalModules" | Get-IISConfigCollection | where { $_.Attributes["name"].value -eq "httpPlatformHandler" }) { exit 1 }',
    provider => powershell,
    require => [File['HttpPlatformHandler.dll'], File['httpplatform_schema.xml']],
}

file { 'c:\aspnetdemo.zip':
    ensure => present,
    source => 'puppet:///extra_files/iis_demo/aspnetdemo.zip',
    notify => Exec['expand_aspnet_site'],
    audit => 'content',
}

exec { 'expand_aspnet_site':
    command => 'Expand-Archive C:\aspnetdemo.zip c:\inetpub\demo\ -Force',
    provider => powershell,
    refreshonly => true,
}
->
exec { 'create_aspnet_site':
    command => 'Import-module IISAdministration; New-IISSite -Name "AspNet5Demo" -PhysicalPath c:\inetpub\demo\AspNet5Demo\wwwroot -BindingInformation "*:8000:"',
    unless => 'Import-module IISAdministration; if(!(Get-IISSite -Name "AspNet5Demo")) { exit 1 }',
    provider => powershell,
}

class { 'windows_firewall': ensure => 'running' }

windows_firewall::exception { 'AspNet5Demo':
    ensure       => present,
    direction    => 'in',
    action       => 'Allow',
    enabled      => 'yes',
    protocol     => 'TCP',
    local_port   => '8000',
    remote_port  => 'any',
    display_name => 'AspNet5Demo',
    description  => 'AspNet5Demo IIS site. [TCP 8000]',
}
