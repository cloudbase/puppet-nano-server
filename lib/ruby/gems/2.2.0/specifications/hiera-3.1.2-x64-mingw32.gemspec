# -*- encoding: utf-8 -*-
# stub: hiera 3.1.2 x64-mingw32 lib

Gem::Specification.new do |s|
  s.name = "hiera"
  s.version = "3.1.2"
  s.platform = "x64-mingw32"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Puppet Labs"]
  s.date = "2016-04-22"
  s.description = "A pluggable data store for hierarcical data"
  s.email = "info@puppetlabs.com"
  s.executables = ["hiera"]
  s.files = ["bin/hiera"]
  s.homepage = "https://github.com/puppetlabs/hiera"
  s.rubygems_version = "2.4.5.1"
  s.summary = "Light weight hierarchical data store"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json_pure>, [">= 0"])
      s.add_runtime_dependency(%q<win32-dir>, ["~> 0.4.8"])
    else
      s.add_dependency(%q<json_pure>, [">= 0"])
      s.add_dependency(%q<win32-dir>, ["~> 0.4.8"])
    end
  else
    s.add_dependency(%q<json_pure>, [">= 0"])
    s.add_dependency(%q<win32-dir>, ["~> 0.4.8"])
  end
end
