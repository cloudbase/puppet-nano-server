dsc_file {'tmpfolder':
    dsc_ensure          => 'present',
    dsc_type            => 'Directory',
    dsc_destinationpath => 'C:\testdir',
  } ->

dsc_registry {'registry_test':
    dsc_ensure    => 'Present',
    dsc_key       => 'HKEY_LOCAL_MACHINE\SOFTWARE\ExampleKey',
    dsc_valuename => 'TestValue',
    dsc_valuedata => 'TestData',
}

registry_key { 'HKLM\Software\NanoDemo':
     ensure => present,
}
->
registry_value {'HKLM\Software\NanoDemo\justavalue':
  ensure => 'present',
  data   => 'Blah',
  type   => 'string',
}

file { 'c:\testacl':
    ensure => 'directory',
  }
 ->
acl { 'c:\testacl':
  inherit_parent_permissions => 'false',
  permissions                => [
   {identity => 'SYSTEM', rights=> ['full']},
   {identity => 'Administrators', rights => ['full']},
   {identity => 'Everyone', rights => ['read', 'execute'], affects => 'self_only'},
   {identity => 'Everyone', rights => ['read', 'execute'], affects => 'children_only'}
  ],
}

host { 'puppet-master.lan':
    ip => '10.14.0.187',
  }
