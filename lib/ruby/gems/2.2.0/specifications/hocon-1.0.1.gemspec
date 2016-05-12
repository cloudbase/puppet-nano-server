# -*- encoding: utf-8 -*-
# stub: hocon 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "hocon"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Chris Price", "Wayne Warren", "Preben Ingvaldsen", "Joe Pinsonault", "Kevin Corcoran"]
  s.date = "2016-03-16"
  s.description = "== A port of the Java {Typesafe Config}[https://github.com/typesafehub/config] library to Ruby"
  s.email = "chris@puppetlabs.com"
  s.homepage = "https://github.com/puppetlabs/ruby-hocon"
  s.licenses = ["Apache License, v2"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0")
  s.rubygems_version = "2.4.5.1"
  s.summary = "HOCON Config Library"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.5"])
      s.add_development_dependency(%q<rspec>, ["~> 2.14"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.5"])
      s.add_dependency(%q<rspec>, ["~> 2.14"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.5"])
    s.add_dependency(%q<rspec>, ["~> 2.14"])
  end
end
