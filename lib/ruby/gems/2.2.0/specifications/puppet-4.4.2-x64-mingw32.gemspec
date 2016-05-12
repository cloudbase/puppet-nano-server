# -*- encoding: utf-8 -*-
# stub: puppet 4.4.2 x64-mingw32 lib

Gem::Specification.new do |s|
  s.name = "puppet"
  s.version = "4.4.2"
  s.platform = "x64-mingw32"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Puppet Labs"]
  s.date = "2016-04-22"
  s.description = "Puppet, an automated configuration management tool"
  s.email = "info@puppetlabs.com"
  s.executables = ["puppet"]
  s.files = ["bin/puppet"]
  s.homepage = "https://github.com/puppetlabs/puppet"
  s.rdoc_options = ["--title", "Puppet - Configuration Management", "--main", "README.md", "--line-numbers"]
  s.rubyforge_project = "puppet"
  s.rubygems_version = "2.4.5.1"
  s.summary = "Puppet, an automated configuration management tool"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<facter>, ["< 4", "> 2.0"])
      s.add_runtime_dependency(%q<hiera>, ["< 4", ">= 2.0"])
      s.add_runtime_dependency(%q<json_pure>, [">= 0"])
      s.add_runtime_dependency(%q<ffi>, ["~> 1.9.6"])
      s.add_runtime_dependency(%q<win32-dir>, ["~> 0.4.9"])
      s.add_runtime_dependency(%q<win32-eventlog>, ["~> 0.6.2"])
      s.add_runtime_dependency(%q<win32-process>, ["~> 0.7.4"])
      s.add_runtime_dependency(%q<win32-security>, ["~> 0.2.5"])
      s.add_runtime_dependency(%q<win32-service>, ["~> 0.8.6"])
      s.add_runtime_dependency(%q<minitar>, ["~> 0.5.4"])
    else
      s.add_dependency(%q<facter>, ["< 4", "> 2.0"])
      s.add_dependency(%q<hiera>, ["< 4", ">= 2.0"])
      s.add_dependency(%q<json_pure>, [">= 0"])
      s.add_dependency(%q<ffi>, ["~> 1.9.6"])
      s.add_dependency(%q<win32-dir>, ["~> 0.4.9"])
      s.add_dependency(%q<win32-eventlog>, ["~> 0.6.2"])
      s.add_dependency(%q<win32-process>, ["~> 0.7.4"])
      s.add_dependency(%q<win32-security>, ["~> 0.2.5"])
      s.add_dependency(%q<win32-service>, ["~> 0.8.6"])
      s.add_dependency(%q<minitar>, ["~> 0.5.4"])
    end
  else
    s.add_dependency(%q<facter>, ["< 4", "> 2.0"])
    s.add_dependency(%q<hiera>, ["< 4", ">= 2.0"])
    s.add_dependency(%q<json_pure>, [">= 0"])
    s.add_dependency(%q<ffi>, ["~> 1.9.6"])
    s.add_dependency(%q<win32-dir>, ["~> 0.4.9"])
    s.add_dependency(%q<win32-eventlog>, ["~> 0.6.2"])
    s.add_dependency(%q<win32-process>, ["~> 0.7.4"])
    s.add_dependency(%q<win32-security>, ["~> 0.2.5"])
    s.add_dependency(%q<win32-service>, ["~> 0.8.6"])
    s.add_dependency(%q<minitar>, ["~> 0.5.4"])
  end
end
