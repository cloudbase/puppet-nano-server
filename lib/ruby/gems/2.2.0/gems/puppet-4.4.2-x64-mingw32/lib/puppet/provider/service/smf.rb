require 'timeout'

# Solaris 10 SMF-style services.
Puppet::Type.type(:service).provide :smf, :parent => :base do
  desc <<-EOT
    Support for Sun's new Service Management Framework.

    Starting a service is effectively equivalent to enabling it, so there is
    only support for starting and stopping services, which also enables and
    disables them, respectively.

    By specifying `manifest => "/path/to/service.xml"`, the SMF manifest will
    be imported if it does not exist.

  EOT

  defaultfor :osfamily => :solaris

  confine :osfamily => :solaris

  commands :adm => "/usr/sbin/svcadm", :svcs => "/usr/bin/svcs"
  commands :svccfg => "/usr/sbin/svccfg"

  def setupservice
      if resource[:manifest]
        [command(:svcs), "-l", @resource[:name]]
        if $CHILD_STATUS.exitstatus == 1
          Puppet.notice "Importing #{@resource[:manifest]} for #{@resource[:name]}"
          svccfg :import, resource[:manifest]
        end
      end
  rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new( "Cannot config #{self.name} to enable it: #{detail}", detail )
  end

  def self.instances
   svcs("-H").split("\n").select{|l| l !~ /^legacy_run/ }.collect do |line|
     state,stime,fmri = line.split(/\s+/)
     status =  case state
               when /online/; :running
               when /maintenance/; :maintenance
               else :stopped
               end
     new({:name => fmri, :ensure => status})
   end
  end

  def enable
    self.start
  end

  def enabled?
    case self.status
    when :running
      return :true
    else
      return :false
    end
  end

  def disable
    self.stop
  end

  def restartcmd
    [command(:adm), :restart, @resource[:name]]
  end

  def startcmd
    self.setupservice
    case self.status
    when :maintenance
      [command(:adm), :clear, @resource[:name]]
    else
      [command(:adm), :enable, "-s", @resource[:name]]
    end
  end

  # Wait for the service to transition into the specified state before returning.
  # This is necessary due to the asynchronous nature of SMF services.
  # desired_state should be online, offline, disabled, or uninitialized.
  # See PUP-5474 for long-term solution to this issue.
  def wait(*desired_state)
    Timeout.timeout(60) do
      loop do
        states = self.service_states
        break if desired_state.include?(states[0]) && states[1] == '-'
        sleep(1)
      end
    end
  rescue Timeout::Error
    raise Puppet::Error.new("Timed out waiting for #{@resource[:name]} to transition states")
  end

  def start
    # Wait for the service to actually start before returning.
    super
    self.wait('online')
  end

  def stop
    # Wait for the service to actually stop before returning.
    super
    self.wait('offline', 'disabled', 'uninitialized')
  end

  def restart
    # Wait for the service to actually start before returning.
    super
    self.wait('online')
  end

  # Determine the current and next states of a service.
  def service_states
    svcs("-H", "-o", "state,nstate", @resource[:name]).chomp.split
  end

  def status
    if @resource[:status]
      super
      return
    end

    begin
      # get the current state and the next state, and if the next
      # state is set (i.e. not "-") use it for state comparison
      states = service_states
      state = states[1] == "-" ? states[0] : states[1]
    rescue Puppet::ExecutionFailure
      info "Could not get status on service #{self.name}"
      return :stopped
    end

    case state
    when "online"
      #self.warning "matched running #{line.inspect}"
      return :running
    when "offline", "disabled", "uninitialized"
      #self.warning "matched stopped #{line.inspect}"
      return :stopped
    when "maintenance"
      return :maintenance
    when "legacy_run"
      raise Puppet::Error,
        "Cannot manage legacy services through SMF"
    else
      raise Puppet::Error,
        "Unmanageable state '#{state}' on service #{self.name}"
    end

  end

  def stopcmd
    [command(:adm), :disable, "-s", @resource[:name]]
  end
end

