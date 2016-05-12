# -*- encoding: utf-8 -*-
# stub: win32-service 0.8.7 ruby lib

Gem::Specification.new do |s|
  s.name = "win32-service"
  s.version = "0.8.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Daniel J. Berger", "Park Heesob"]
  s.date = "2015-07-15"
  s.description = "    The win32-service library provides a Ruby interface to services on\n    MS Windows. You can create new services, or control, configure and\n    inspect existing services.\n\n    In addition, you can create a pure Ruby service by using the Daemon\n    class that is included as part of the library.\n"
  s.email = "djberg96@gmail.com"
  s.extra_rdoc_files = ["CHANGES", "README", "MANIFEST", "doc/service.txt", "doc/daemon.txt"]
  s.files = ["CHANGES", "MANIFEST", "README", "doc/daemon.txt", "doc/service.txt"]
  s.homepage = "http://github.com/djberg96/win32-service"
  s.licenses = ["Artistic 2.0"]
  s.rubygems_version = "2.4.5.1"
  s.summary = "An interface for MS Windows services"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ffi>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<ffi>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<ffi>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
