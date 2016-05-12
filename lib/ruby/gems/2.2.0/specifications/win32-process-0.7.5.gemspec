# -*- encoding: utf-8 -*-
# stub: win32-process 0.7.5 ruby lib

Gem::Specification.new do |s|
  s.name = "win32-process"
  s.version = "0.7.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Daniel Berger", "Park Heesob"]
  s.date = "2015-03-03"
  s.description = "    The win32-process library implements several Process methods that are\n    either unimplemented or dysfunctional in some way in the default Ruby\n    implementation. Examples include Process.kill, Process.uid and\n    Process.create.\n"
  s.email = "djberg96@gmail.com"
  s.extra_rdoc_files = ["README", "CHANGES", "MANIFEST"]
  s.files = ["CHANGES", "MANIFEST", "README"]
  s.homepage = "https://github.com/djberg96/win32-process"
  s.licenses = ["Artistic 2.0"]
  s.required_ruby_version = Gem::Requirement.new("> 1.9.0")
  s.rubygems_version = "2.4.5.1"
  s.summary = "Adds and redefines several Process methods for MS Windows"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ffi>, [">= 1.0.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 2.4.0"])
    else
      s.add_dependency(%q<ffi>, [">= 1.0.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 2.4.0"])
    end
  else
    s.add_dependency(%q<ffi>, [">= 1.0.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 2.4.0"])
  end
end
