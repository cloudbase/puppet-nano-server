# -*- encoding: utf-8 -*-
# stub: win32-security 0.2.5 ruby lib

Gem::Specification.new do |s|
  s.name = "win32-security"
  s.version = "0.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Daniel J. Berger", "Park Heesob"]
  s.date = "2014-02-25"
  s.description = "    The win32-security library provides an interface for dealing with\n    security related aspects of MS Windows. At the moment it provides an\n    interface for inspecting or creating SID's.\n"
  s.email = "djberg96@gmail.com"
  s.extra_rdoc_files = ["README", "CHANGES", "MANIFEST"]
  s.files = ["CHANGES", "MANIFEST", "README"]
  s.homepage = "https://github.com/djberg96/win32-security"
  s.licenses = ["Artistic 2.0"]
  s.rubyforge_project = "win32utils"
  s.rubygems_version = "2.4.5.1"
  s.summary = "A library for dealing with aspects of Windows security."

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ffi>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 2.5.0"])
      s.add_development_dependency(%q<sys-admin>, [">= 1.6.0"])
    else
      s.add_dependency(%q<ffi>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 2.5.0"])
      s.add_dependency(%q<sys-admin>, [">= 1.6.0"])
    end
  else
    s.add_dependency(%q<ffi>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 2.5.0"])
    s.add_dependency(%q<sys-admin>, [">= 1.6.0"])
  end
end
