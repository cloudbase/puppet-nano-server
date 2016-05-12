module Facter::Util::WMI
  class << self
    def connect(uri = wmi_resource_uri)
      #puts uri
      require 'win32ole'
      #WIN32OLE.connect(uri)      
      swbem = WIN32OLE.new("WbemScripting.SWbemLocator")
      swbem.ConnectServer(".", "root\\cimv2")
    end

    def wmi_resource_uri( host = '.' )
      "winmgmts:{impersonationLevel=impersonate}!//#{host}/root/cimv2"
    end

    def execquery(query)
      #puts query
      connect().execquery(query)
    end
  end
end
