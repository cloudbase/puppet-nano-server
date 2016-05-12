module Puppet

  def self.default_diffargs
    if (Facter.value(:kernel) == "AIX" && Facter.value(:kernelmajversion) == "5300")
      ""
    else
      "-u"
    end
  end

  ############################################################################################
  # NOTE: For information about the available values for the ":type" property of settings,
  #   see the docs for Settings.define_settings
  ############################################################################################

  AS_DURATION = %q{This setting can be a time interval in seconds (30 or 30s), minutes (30m), hours (6h), days (2d), or years (5y).}

  # This is defined first so that the facter implementation is replaced before other setting defaults are evaluated.
  define_settings(:main,
    :cfacter => {
        :default => false,
        :type    => :boolean,
        :desc    => 'Whether to enable a pre-Facter 3.0 release of native Facter (distributed as
          the "cfacter" package). This is not necessary if Facter 3.0 or later is installed.
          This setting is deprecated, as Facter 3 is now the default in puppet-agent.',
        :hook    => proc do |value|
          return unless value
          raise ArgumentError, 'facter has already evaluated facts.' if Facter.instance_variable_get(:@collection)
          raise ArgumentError, 'cfacter version 0.2.0 or later is not installed.' unless Puppet.features.cfacter?
          CFacter.initialize

          # Setup Facter's logging again now that native facter is initialized
          Puppet::Util::Logging.setup_facter_logging!
        end
    }
  )

  define_settings(:main,
    :confdir  => {
        :default  => nil,
        :type     => :directory,
        :desc     => "The main Puppet configuration directory.  The default for this setting
          is calculated based on the user.  If the process is running as root or
          the user that Puppet is supposed to run as, it defaults to a system
          directory, but if it's running as any other user, it defaults to being
          in the user's home directory.",
    },
    :codedir  => {
        :default  => nil,
        :type     => :directory,
        :desc     => "The main Puppet code directory.  The default for this setting
          is calculated based on the user.  If the process is running as root or
          the user that Puppet is supposed to run as, it defaults to a system
          directory, but if it's running as any other user, it defaults to being
          in the user's home directory.",
    },
    :vardir   => {
        :default  => nil,
        :type     => :directory,
        :owner    => "service",
        :group    => "service",
        :desc     => "Where Puppet stores dynamic and growing data.  The default for this
          setting is calculated specially, like `confdir`_.",
    },

    ### NOTE: this setting is usually being set to a symbol value.  We don't officially have a
    ###     setting type for that yet, but we might want to consider creating one.
    :name     => {
        :default  => nil,
        :desc     => "The name of the application, if we are running as one.  The
          default is essentially $0 without the path or `.rb`.",
    }
  )

  define_settings(:main,
    :logdir => {
        :default  => nil,
        :type     => :directory,
        :mode     => "0750",
        :owner    => "service",
        :group    => "service",
        :desc     => "The directory in which to store log files",
    },
    :log_level => {
      :default    => 'notice',
      :type       => :enum,
      :values     => ["debug","info","notice","warning","err","alert","emerg","crit"],
      :desc       => "Default logging level for messages from Puppet. Allowed values are:

        * debug
        * info
        * notice
        * warning
        * err
        * alert
        * emerg
        * crit
        ",
      :hook => proc {|value| Puppet::Util::Log.level = value },
      :call_hook => :on_initialize_and_write,
    },
    :disable_warnings => {
      :default => [],
      :type    => :array,
      :desc    => "A comma-separated list of warning types to suppress. If large numbers
        of warnings are making Puppet's logs too large or difficult to use, you
        can temporarily silence them with this setting.

        If you are preparing to upgrade Puppet to a new major version, you
        should re-enable all warnings for a while.

        Valid values for this setting are:

        * `deprecations` --- disables deprecation warnings.
        * `undefined_variables` --- disables warnings about non existing variables.",
      :hook      => proc do |value|
        values = munge(value)
        valid   = %w[deprecations undefined_variables]
        invalid = values - (values & valid)
        if not invalid.empty?
          raise ArgumentError, "Cannot disable unrecognized warning types #{invalid.inspect}. Valid values are #{valid.inspect}."
        end
      end
    }
  )

  define_settings(:main,
    :priority => {
      :default => nil,
      :type    => :priority,
      :desc    => "The scheduling priority of the process.  Valid values are 'high',
        'normal', 'low', or 'idle', which are mapped to platform-specific
        values.  The priority can also be specified as an integer value and
        will be passed as is, e.g. -5.  Puppet must be running as a privileged
        user in order to increase scheduling priority.",
    },
    :trace => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Whether to print stack traces on some errors",
        :hook     => proc do |value|
          # Enable or disable Facter's trace option too
          Facter.trace(value) if Facter.respond_to? :trace
        end
    },
    :profile => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Whether to enable experimental performance profiling",
    },
    :static_catalogs => {
      :default    => true,
      :type       => :boolean,
      :desc       => "Whether to compile a static catalog."
    },
    :strict_environment_mode => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether the agent specified environment should be considered authoritative,
        causing the run to fail if the retrieved catalog does not match it.",
    },
    :autoflush => {
      :default => true,
      :type       => :boolean,
      :desc       => "Whether log files should always flush to disk.",
      :hook       => proc { |value| Log.autoflush = value }
    },
    :syslogfacility => {
        :default  => "daemon",
        :desc     => "What syslog facility to use when logging to syslog.
          Syslog has a fixed list of valid facilities, and you must
          choose one of those; you cannot just make one up."
    },
    :statedir => {
        :default  => "$vardir/state",
        :type     => :directory,
        :mode     => "01755",
        :desc     => "The directory where Puppet state is stored.  Generally,
          this directory can be removed without causing harm (although it
          might result in spurious service restarts)."
    },
    :rundir => {
      :default  => nil,
      :type     => :directory,
      :mode     => "0755",
      :owner    => "service",
      :group    => "service",
      :desc     => "Where Puppet PID files are kept."
    },
    :genconfig => {
        :default  => false,
        :type     => :boolean,
        :desc     => "When true, causes Puppet applications to print an example config file
          to stdout and exit. The example will include descriptions of each
          setting, and the current (or default) value of each setting,
          incorporating any settings overridden on the CLI (with the exception
          of `genconfig` itself). This setting only makes sense when specified
          on the command line as `--genconfig`.",
    },
    :genmanifest => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Whether to just print a manifest to stdout and exit.  Only makes
          sense when specified on the command line as `--genmanifest`.  Takes into account arguments specified
          on the CLI.",
    },
    :configprint => {
        :default  => "",
        :desc     => "Print the value of a specific configuration setting.  If the name of a
          setting is provided for this, then the value is printed and puppet
          exits.  Comma-separate multiple values.  For a list of all values,
          specify 'all'.",
    },
    :color => {
      :default => "ansi",
      :type    => :string,
      :desc    => "Whether to use colors when logging to the console.  Valid values are
        `ansi` (equivalent to `true`), `html`, and `false`, which produces no color.
        Defaults to false on Windows, as its console does not support ansi colors.",
    },
    :mkusers => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Whether to create the necessary user and group that puppet agent will run as.",
    },
    :manage_internal_file_permissions => {
        :default  => true,
        :type     => :boolean,
        :desc     => "Whether Puppet should manage the owner, group, and mode of files it uses internally",
    },
    :onetime => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Perform one configuration run and exit, rather than spawning a long-running
          daemon. This is useful for interactively running puppet agent, or
          running puppet agent from cron.",
        :short    => 'o',
    },
    :path => {
        :default          => "none",
        :desc             => "The shell search path.  Defaults to whatever is inherited
          from the parent process.

          This setting can only be set in the `[main]` section of puppet.conf; it cannot
          be set in `[master]`, `[agent]`, or an environment config section.",
        :call_hook => :on_define_and_write,
        :hook             => proc do |value|
          Puppet::Util.set_env('PATH', '') if Puppet::Util.get_env('PATH').nil?
          Puppet::Util.set_env('PATH', value) unless value == 'none'
          paths = Puppet::Util.get_env('PATH').split(File::PATH_SEPARATOR)
          Puppet::Util::Platform.default_paths.each do |path|
            Puppet::Util.set_env('PATH', Puppet::Util.get_env('PATH') + File::PATH_SEPARATOR + path) unless paths.include?(path)
          end
          value
        end
    },
    :libdir => {
        :type           => :directory,
        :default        => "$vardir/lib",
        :desc           => "An extra search path for Puppet.  This is only useful
          for those files that Puppet will load on demand, and is only
          guaranteed to work for those cases.  In fact, the autoload
          mechanism is responsible for making sure this directory
          is in Ruby's search path\n",
      :call_hook => :on_initialize_and_write,
      :hook             => proc do |value|
        $LOAD_PATH.delete(@oldlibdir) if defined?(@oldlibdir) && $LOAD_PATH.include?(@oldlibdir)
        @oldlibdir = value
        $LOAD_PATH << value
      end
    },
    :environment => {
        :default  => "production",
        :desc     => "The environment Puppet is running in.  For clients
          (e.g., `puppet agent`) this determines the environment itself, which
          is used to find modules and much more.  For servers (i.e., `puppet master`)
          this provides the default environment for nodes we know nothing about."
    },
    :environmentpath => {
      :default => "$codedir/environments",
      :desc    => "A search path for directory environments, as a list of directories
        separated by the system path separator character. (The POSIX path separator
        is ':', and the Windows path separator is ';'.)

        This setting must have a value set to enable **directory environments.** The
        recommended value is `$codedir/environments`. For more details, see
        https://docs.puppetlabs.com/puppet/latest/reference/environments.html",
      :type    => :path,
    },
    :always_cache_features => {
      :type     => :boolean,
      :default  => false,
      :desc     => <<-'EOT'
        Affects how we cache attempts to load Puppet 'features'.  If false, then
        calls to `Puppet.features.<feature>?` will always attempt to load the
        feature (which can be an expensive operation) unless it has already been
        loaded successfully.  This makes it possible for a single agent run to,
        e.g., install a package that provides the underlying capabilities for
        a feature, and then later load that feature during the same run (even if
        the feature had been tested earlier and had not been available).

        If this setting is set to true, then features will only be checked once,
        and if they are not available, the negative result is cached and returned
        for all subsequent attempts to load the feature.  This behavior is almost
        always appropriate for the server, and can result in a significant performance
        improvement for features that are checked frequently.
      EOT
    },
    :diff_args => {
        :default  => lambda { default_diffargs },
        :desc     => "Which arguments to pass to the diff command when printing differences between
          files. The command to use can be chosen with the `diff` setting.",
    },
    :diff => {
      :default => (Puppet.features.microsoft_windows? ? "" : "diff"),
      :desc    => "Which diff command to use when printing differences between files. This setting
          has no default value on Windows, as standard `diff` is not available, but Puppet can use many
          third-party diff tools.",
    },
    :show_diff => {
        :type     => :boolean,
        :default  => false,
        :desc     => "Whether to log and report a contextual diff when files are being replaced.
          This causes partial file contents to pass through Puppet's normal
          logging and reporting system, so this setting should be used with
          caution if you are sending Puppet's reports to an insecure
          destination. This feature currently requires the `diff/lcs` Ruby
          library.",
    },
    :daemonize => {
        :type     => :boolean,
        :default  => (Puppet.features.microsoft_windows? ? false : true),
        :desc     => "Whether to send the process into the background.  This defaults
          to true on POSIX systems, and to false on Windows (where Puppet
          currently cannot daemonize).",
        :short    => "D",
        :hook     => proc do |value|
          if value and Puppet.features.microsoft_windows?
            raise "Cannot daemonize on Windows"
          end
      end
    },
    :maximum_uid => {
        :default  => 4294967290,
        :desc     => "The maximum allowed UID.  Some platforms use negative UIDs
          but then ship with tools that do not know how to handle signed ints,
          so the UIDs show up as huge numbers that can then not be fed back into
          the system.  This is a hackish way to fail in a slightly more useful
          way when that happens.",
    },
    :route_file => {
      :default    => "$confdir/routes.yaml",
      :desc       => "The YAML file containing indirector route configuration.",
    },
    :node_terminus => {
      :type       => :terminus,
      :default    => "plain",
      :desc       => "Where to find information about nodes.",
    },
    :node_cache_terminus => {
      :type       => :terminus,
      :default    => nil,
      :desc       => "How to store cached nodes.
      Valid values are (none), 'json', 'msgpack', 'yaml' or write only yaml ('write_only_yaml').
      The master application defaults to 'write_only_yaml', all others to none.",
    },
    :data_binding_terminus => {
      :type    => :terminus,
      :default => "hiera",
      :desc    => "Where to retrive information about data.",
    },
    :hiera_config => {
      :default => "$codedir/hiera.yaml",
      :desc    => "The hiera configuration file. Puppet only reads this file on startup, so you must restart the puppet master every time you edit it.",
      :type    => :file,
    },
    :binder_config => {
      :default => nil,
      :desc    => "The binder configuration file. Puppet reads this file on each request to configure the bindings system.
      If set to nil (the default), a $confdir/binder_config.yaml is optionally loaded. If it does not exists, a default configuration
      is used. If the setting :binding_config is specified, it must reference a valid and existing yaml file.",
      :type    => :file,
    },
    :catalog_terminus => {
      :type       => :terminus,
      :default    => "compiler",
      :desc       => "Where to get node catalogs.  This is useful to change if, for instance,
      you'd like to pre-compile catalogs and store them in memcached or some other easily-accessed store.",
    },
    :catalog_cache_terminus => {
      :type       => :terminus,
      :default    => nil,
      :desc       => "How to store cached catalogs. Valid values are 'json', 'msgpack' and 'yaml'. The agent application defaults to 'json'."
    },
    :facts_terminus => {
      :default => 'facter',
      :desc => "The node facts terminus.",
    },
    :default_file_terminus => {
      :type       => :terminus,
      :default    => "rest",
      :desc       => "The default source for files if no server is given in a
      uri, e.g. puppet:///file. The default of `rest` causes the file to be
      retrieved using the `server` setting. When running `apply` the default
      is `file_server`, causing requests to be filled locally."
    },
    :http_proxy_host => {
      :default    => "none",
      :desc       => "The HTTP proxy host to use for outgoing connections.  Note: You
      may need to use a FQDN for the server hostname when using a proxy. Environment variable
      http_proxy or HTTP_PROXY will override this value",
    },
    :http_proxy_port => {
      :default    => 3128,
      :desc       => "The HTTP proxy port to use for outgoing connections",
    },
    :http_proxy_user => {
      :default    => "none",
      :desc       => "The user name for an authenticated HTTP proxy. Requires the `http_proxy_host` setting.",
    },
    :http_proxy_password =>{
      :default    => "none",
      :hook       => proc do |value|
        if Puppet.settings[:http_proxy_password] =~ /[@!# \/]/
          raise "Passwords set in the http_proxy_password setting must be valid as part of a URL, and any reserved characters must be URL-encoded. We received: #{value}"
        end
      end,
      :desc       => "The password for the user of an authenticated HTTP proxy.
        Requires the `http_proxy_user` setting.

        Note that passwords must be valid when used as part of a URL. If a password
        contains any characters with special meanings in URLs (as specified by RFC 3986
        section 2.2), they must be URL-encoded. (For example, `#` would become `%23`.)",
    },
    :http_keepalive_timeout => {
      :default    => "4s",
      :type       => :duration,
      :desc       => "The maximum amount of time a persistent HTTP connection can remain idle in the connection pool, before it is closed.  This timeout should be shorter than the keepalive timeout used on the HTTP server, e.g. Apache KeepAliveTimeout directive.
      #{AS_DURATION}"
    },
    :http_debug => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether to write HTTP request and responses to stderr. This should never be used in a production environment."
    },
    :http_connect_timeout => {
      :default => "2m",
      :type    => :duration,
      :desc    => "The maximum amount of time to wait when establishing an HTTP connection. The default
      value is 2 minutes.
      #{AS_DURATION}",
    },
    :http_read_timeout => {
      :type    => :duration,
      :desc    => "The time to wait for one block to be read from an HTTP connection. If nothing is
      read after the elapsed interval then the connection will be closed. The default value is unlimited.
      #{AS_DURATION}",
    },
    :filetimeout => {
      :default    => "15s",
      :type       => :duration,
      :desc       => "The minimum time to wait between checking for updates in
      configuration files.  This timeout determines how quickly Puppet checks whether
      a file (such as manifests or templates) has changed on disk. #{AS_DURATION}",
    },
    :environment_timeout => {
      :default    => "0",
      :type       => :ttl,
      :desc       => "How long the Puppet master should cache data it loads from an
      environment.
      #{AS_DURATION}
      A value of `0` will disable caching. This setting can also be set to
      `unlimited`, which will cache environments until the master is restarted
      or told to refresh the cache.

      You should change this setting once your Puppet deployment is doing
      non-trivial work. We chose the default value of `0` because it lets new
      users update their code without any extra steps, but it lowers the
      performance of your Puppet master.

      We recommend setting this to `unlimited` and explicitly refreshing your
      Puppet master as part of your code deployment process.

      * With Puppet Server, you should refresh environments by calling the
        `environment-cache` API endpoint. See the docs for the Puppet Server
        administrative API.
      * With a Rack Puppet master, you should restart the web server or the
        application server. Passenger lets you touch a `restart.txt` file to
        refresh an application without restarting Apache; see the Passenger docs
        for details.

      We don't recommend using any value other than `0` or `unlimited`, since
      most Puppet masters use a pool of Ruby interpreters which all have their
      own cache timers. When these timers drift out of sync, agents can be served
      inconsistent catalogs."
    },
    :environment_data_provider => {
      :default    => "none",
      :desc       => "The name of a registered environment data provider used when obtaining environment
      specific data. The three built in and registered providers are 'none' (no data), 'function' (data
      obtained by calling the function 'environment::data()') and 'hiera' (data obtained using a data
      provider configured using a hiera.yaml file in root of the environment).
      Other environment data providers may be registered in modules on the module path. For such
      custom data providers see the respective module documentation."
    },
    :prerun_command => {
      :default    => "",
      :desc       => "A command to run before every agent run.  If this command returns a non-zero
      return code, the entire Puppet run will fail.",
    },
    :postrun_command => {
      :default    => "",
      :desc       => "A command to run after every agent run.  If this command returns a non-zero
      return code, the entire Puppet run will be considered to have failed, even though it might have
      performed work during the normal run.",
    },
    :freeze_main => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Freezes the 'main' class, disallowing any code to be added to it.  This
          essentially means that you can't have any code outside of a node,
          class, or definition other than in the site manifest.",
    },
    :trusted_server_facts => {
      :default => false,
      :type    => :boolean,
      :desc    => "When enabled, Puppet creates a protected top-scope variable called $server_facts.
        This variable name can't be re-used in any local scope, and can't be overridden
        by agent-provided facts.

        The $server_facts variable is a hash, containing server-provided information
        like the current node's environment and the version of Puppet running on the server.",
    },
    :preview_outputdir => {
      :default => '$vardir/preview',
      :type     => :directory,
      :mode     => "0750",
      :owner    => "service",
      :group    => "service",
      :desc    => "The directory where catalog previews per node are generated."
    }
  )

  define_settings(:main,
      :app_management => {
          :default  => false,
          :type     => :boolean,
          :desc     => "Whether the application management feature is on or off. You must restart Puppet Server after changing this setting.",
      }
  )

  Puppet.define_settings(:module_tool,
    :module_repository  => {
      :default  => 'https://forgeapi.puppetlabs.com',
      :desc     => "The module repository",
    },
    :module_working_dir => {
        :default  => (Puppet.features.microsoft_windows? ? Dir.tmpdir() : '$vardir/puppet-module'),
        :desc     => "The directory into which module tool data is stored",
    },
    :module_skeleton_dir => {
        :default  => '$module_working_dir/skeleton',
        :desc     => "The directory which the skeleton for module tool generate is stored.",
    },
    :forge_authorization => {
        :default  => nil,
        :desc     => "The authorization key to connect to the Puppet Forge. Leave blank for unauthorized or license based connections",
    },
    :module_groups => {
        :default  => nil,
        :desc     => "Extra module groups to request from the Puppet Forge. This is an internal setting, and users should never change it.",
    }
  )

    Puppet.define_settings(
    :main,

    # We have to downcase the fqdn, because the current ssl stuff (as oppsed to in master) doesn't have good facilities for
    # manipulating naming.
    :certname => {
      :default => lambda { Puppet::Settings.default_certname.downcase },
      :desc => "The name to use when handling certificates. When a node
        requests a certificate from the CA puppet master, it uses the value of the
        `certname` setting as its requested Subject CN.

        This is the name used when managing a node's permissions in
        [auth.conf](https://docs.puppetlabs.com/puppet/latest/reference/config_file_auth.html).
        In most cases, it is also used as the node's name when matching
        [node definitions](https://docs.puppetlabs.com/puppet/latest/reference/lang_node_definitions.html)
        and requesting data from an ENC. (This can be changed with the `node_name_value`
        and `node_name_fact` settings, although you should only do so if you have
        a compelling reason.)

        A node's certname is available in Puppet manifests as `$trusted['certname']`. (See
        [Facts and Built-In Variables](https://docs.puppetlabs.com/puppet/latest/reference/lang_facts_and_builtin_vars.html)
        for more details.)

        * For best compatibility, you should limit the value of `certname` to
          only use letters, numbers, periods, underscores, and dashes. (That is,
          it should match `/\A[a-z0-9._-]+\Z/`.)
        * The special value `ca` is reserved, and can't be used as the certname
          for a normal node.

        Defaults to the node's fully qualified domain name.",
      :hook => proc { |value| raise(ArgumentError, "Certificate names must be lower case; see #1168") unless value == value.downcase }},
    :dns_alt_names => {
      :default => '',
      :desc    => <<EOT,
A comma-separated list of alternate DNS names for Puppet Server. These are extra
hostnames (in addition to its `certname`) that the server is allowed to use when
serving agents. Puppet checks this setting when automatically requesting a
certificate for Puppet agent or Puppet Server, and when manually generating a
certificate with `puppet cert generate`.

In order to handle agent requests at a given hostname (like
"puppet.example.com"), Puppet Server needs a certificate that proves it's
allowed to use that name; if a server shows a certificate that doesn't include
its hostname, Puppet agents will refuse to trust it. If you use a single
hostname for Puppet traffic but load-balance it to multiple Puppet Servers, each
of those servers needs to include the official hostname in its list of extra
names.

**Note:** The list of alternate names is locked in when the server's
certificate is signed. If you need to change the list later, you can't just
change this setting; you also need to:

* On the server: Stop Puppet Server.
* On the CA server: Revoke and clean the server's old certificate. (`puppet cert clean <NAME>`)
* On the server: Delete the old certificate (and any old certificate signing requests)
  from the [ssldir](https://docs.puppetlabs.com/puppet/latest/reference/dirs_ssldir.html).
* On the server: Run `puppet agent -t --ca_server <CA HOSTNAME>` to request a new certificate
* On the CA server: Sign the certificate request, explicitly allowing alternate names
  (`puppet cert sign --allow-dns-alt-names <NAME>`).
* On the server: Run `puppet agent -t --ca_server <CA HOSTNAME>` to retrieve the cert.
* On the server: Start Puppet Server again.

To see all the alternate names your servers are using, log into your CA server
and run `puppet cert list -a`, then check the output for `(alt names: ...)`.
Most agent nodes should NOT have alternate names; the only certs that should
have them are Puppet Server nodes that you want other agents to trust.
EOT
    },
    :csr_attributes => {
      :default => "$confdir/csr_attributes.yaml",
      :type => :file,
      :desc => <<EOT
An optional file containing custom attributes to add to certificate signing
requests (CSRs). You should ensure that this file does not exist on your CA
puppet master; if it does, unwanted certificate extensions may leak into
certificates created with the `puppet cert generate` command.

If present, this file must be a YAML hash containing a `custom_attributes` key
and/or an `extension_requests` key. The value of each key must be a hash, where
each key is a valid OID and each value is an object that can be cast to a string.

Custom attributes can be used by the CA when deciding whether to sign the
certificate, but are then discarded. Attribute OIDs can be any OID value except
the standard CSR attributes (i.e. attributes described in RFC 2985 section 5.4).
This is useful for embedding a pre-shared key for autosigning policy executables
(see the `autosign` setting), often by using the `1.2.840.113549.1.9.7`
("challenge password") OID.

Extension requests will be permanently embedded in the final certificate.
Extension OIDs must be in the "ppRegCertExt" (`1.3.6.1.4.1.34380.1.1`) or
"ppPrivCertExt" (`1.3.6.1.4.1.34380.1.2`) OID arcs. The ppRegCertExt arc is
reserved for four of the most common pieces of data to embed: `pp_uuid` (`.1`),
`pp_instance_id` (`.2`), `pp_image_name` (`.3`), and `pp_preshared_key` (`.4`)
--- in the YAML file, these can be referred to by their short descriptive names
instead of their full OID. The ppPrivCertExt arc is unregulated, and can be used
for site-specific extensions.
EOT
    },
    :certdir => {
      :default => "$ssldir/certs",
      :type   => :directory,
      :mode => "0755",
      :owner => "service",
      :group => "service",
      :desc => "The certificate directory."
    },
    :ssldir => {
      :default => "$confdir/ssl",
      :type   => :directory,
      :mode => "0771",
      :owner => "service",
      :group => "service",
      :desc => "Where SSL certificates are kept."
    },
    :publickeydir => {
      :default => "$ssldir/public_keys",
      :type   => :directory,
      :mode => "0755",
      :owner => "service",
      :group => "service",
      :desc => "The public key directory."
    },
    :requestdir => {
      :default => "$ssldir/certificate_requests",
      :type => :directory,
      :mode => "0755",
      :owner => "service",
      :group => "service",
      :desc => "Where host certificate requests are stored."
    },
    :privatekeydir => {
      :default => "$ssldir/private_keys",
      :type   => :directory,
      :mode => "0750",
      :owner => "service",
      :group => "service",
      :desc => "The private key directory."
    },
    :privatedir => {
      :default => "$ssldir/private",
      :type   => :directory,
      :mode => "0750",
      :owner => "service",
      :group => "service",
      :desc => "Where the client stores private certificate information."
    },
    :passfile => {
      :default => "$privatedir/password",
      :type   => :file,
      :mode => "0640",
      :owner => "service",
      :group => "service",
      :desc => "Where puppet agent stores the password for its private key.
        Generally unused."
    },
    :hostcsr => {
      :default => "$ssldir/csr_$certname.pem",
      :type   => :file,
      :mode => "0644",
      :owner => "service",
      :group => "service",
      :desc => "Where individual hosts store and look for their certificate requests."
    },
    :hostcert => {
      :default => "$certdir/$certname.pem",
      :type   => :file,
      :mode => "0644",
      :owner => "service",
      :group => "service",
      :desc => "Where individual hosts store and look for their certificates."
    },
    :hostprivkey => {
      :default => "$privatekeydir/$certname.pem",
      :type   => :file,
      :mode => "0640",
      :owner => "service",
      :group => "service",
      :desc => "Where individual hosts store and look for their private key."
    },
    :hostpubkey => {
      :default => "$publickeydir/$certname.pem",
      :type   => :file,
      :mode => "0644",
      :owner => "service",
      :group => "service",
      :desc => "Where individual hosts store and look for their public key."
    },
    :localcacert => {
      :default => "$certdir/ca.pem",
      :type   => :file,
      :mode => "0644",
      :owner => "service",
      :group => "service",
      :desc => "Where each client stores the CA certificate."
    },
    :ssl_client_ca_auth => {
      :type  => :file,
      :mode  => "0644",
      :owner => "service",
      :group => "service",
      :desc  => "Certificate authorities who issue server certificates.  SSL servers will not be
        considered authentic unless they possess a certificate issued by an authority
        listed in this file.  If this setting has no value then the Puppet master's CA
        certificate (localcacert) will be used."
    },
    :ssl_server_ca_auth => {
      :type  => :file,
      :mode  => "0644",
      :owner => "service",
      :group => "service",
      :desc  => "Certificate authorities who issue client certificates.  SSL clients will not be
        considered authentic unless they possess a certificate issued by an authority
        listed in this file.  If this setting has no value then the Puppet master's CA
        certificate (localcacert) will be used."
    },
    :hostcrl => {
      :default => "$ssldir/crl.pem",
      :type   => :file,
      :mode => "0644",
      :owner => "service",
      :group => "service",
      :desc => "Where the host's certificate revocation list can be found.
        This is distinct from the certificate authority's CRL."
    },
    :certificate_revocation => {
        :default  => true,
        :type     => :boolean,
        :desc     => "Whether certificate revocation should be supported by downloading a
          Certificate Revocation List (CRL)
          to all clients.  If enabled, CA chaining will almost definitely not work.",
    },
    :digest_algorithm => {
        :default  => 'md5',
        :type     => :enum,
        :values => ["md5", "sha256"],
        :desc     => 'Which digest algorithm to use for file resources and the filebucket.
                      Valid values are md5, sha256. Default is md5.',
    },
    :supported_checksum_types => {
      :default => ['md5', 'sha256'],
      :type    => :array,
      :desc    => 'Checksum types supported by this agent for use in file resources of a
                   static catalog. Values must be comma-separated. Valid types are md5,
                   md5lite, sha256, sha256lite, sha1, sha1lite, mtime, ctime.',
      :hook    => proc do |value|
        values = munge(value)
        valid   = ['md5', 'md5lite', 'sha256', 'sha256lite', 'sha1', 'sha1lite', 'mtime', 'ctime']
        invalid = values.reject {|alg| valid.include?(alg)}
        if not invalid.empty?
          raise ArgumentError, "Unrecognized checksum types #{invalid} are not supported. Valid values are #{valid}."
        end
      end
    }
  )

    define_settings(
    :ca,
    :ca_name => {
      :default    => "Puppet CA: $certname",
      :desc       => "The name to use the Certificate Authority certificate.",
    },
    :cadir => {
      :default => "$ssldir/ca",
      :type => :directory,
      :owner => "service",
      :group => "service",
      :mode => "0755",
      :desc => "The root directory for the certificate authority."
    },
    :cacert => {
      :default => "$cadir/ca_crt.pem",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0644",
      :desc => "The CA certificate."
    },
    :cakey => {
      :default => "$cadir/ca_key.pem",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0640",
      :desc => "The CA private key."
    },
    :capub => {
      :default => "$cadir/ca_pub.pem",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0644",
      :desc => "The CA public key."
    },
    :cacrl => {
      :default => "$cadir/ca_crl.pem",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0644",
      :desc => "The certificate revocation list (CRL) for the CA. Will be used if present but otherwise ignored.",
    },
    :caprivatedir => {
      :default => "$cadir/private",
      :type => :directory,
      :owner => "service",
      :group => "service",
      :mode => "0750",
      :desc => "Where the CA stores private certificate information."
    },
    :csrdir => {
      :default => "$cadir/requests",
      :type => :directory,
      :owner => "service",
      :group => "service",
      :mode  => "0755",
      :desc => "Where the CA stores certificate requests"
    },
    :signeddir => {
      :default => "$cadir/signed",
      :type => :directory,
      :owner => "service",
      :group => "service",
      :mode => "0755",
      :desc => "Where the CA stores signed certificates."
    },
    :capass => {
      :default => "$caprivatedir/ca.pass",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0640",
      :desc => "Where the CA stores the password for the private key."
    },
    :serial => {
      :default => "$cadir/serial",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0644",
      :desc => "Where the serial number for certificates is stored."
    },
    :autosign => {
      :default => "$confdir/autosign.conf",
      :type => :autosign,
      :desc => "Whether (and how) to autosign certificate requests. This setting
        is only relevant on a puppet master acting as a certificate authority (CA).

        Valid values are true (autosigns all certificate requests; not recommended),
        false (disables autosigning certificates), or the absolute path to a file.

        The file specified in this setting may be either a **configuration file**
        or a **custom policy executable.** Puppet will automatically determine
        what it is: If the Puppet user (see the `user` setting) can execute the
        file, it will be treated as a policy executable; otherwise, it will be
        treated as a config file.

        If a custom policy executable is configured, the CA puppet master will run it
        every time it receives a CSR. The executable will be passed the subject CN of the
        request _as a command line argument,_ and the contents of the CSR in PEM format
        _on stdin._ It should exit with a status of 0 if the cert should be autosigned
        and non-zero if the cert should not be autosigned.

        If a certificate request is not autosigned, it will persist for review. An admin
        user can use the `puppet cert sign` command to manually sign it, or can delete
        the request.

        For info on autosign configuration files, see
        [the guide to Puppet's config files](http://docs.puppetlabs.com/puppet/latest/reference/config_about_settings.html).",
    },
    :allow_duplicate_certs => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether to allow a new certificate
      request to overwrite an existing certificate.",
    },
    :ca_ttl => {
      :default    => "5y",
      :type       => :duration,
      :desc       => "The default TTL for new certificates.
      #{AS_DURATION}"
    },
    :req_bits => {
      :default    => 4096,
      :desc       => "The bit length of the certificates.",
    },
    :keylength => {
      :default    => 4096,
      :desc       => "The bit length of keys.",
    },
    :cert_inventory => {
      :default => "$cadir/inventory.txt",
      :type => :file,
      :mode => "0644",
      :owner => "service",
      :group => "service",
      :desc => "The inventory file. This is a text file to which the CA writes a
        complete listing of all certificates."
    }
  )

  # Define the config default.

    define_settings(:application,
      :config_file_name => {
          :type     => :string,
          :default  => Puppet::Settings.default_config_file_name,
          :desc     => "The name of the puppet config file.",
      },
      :config => {
          :type => :file,
          :default  => "$confdir/${config_file_name}",
          :desc     => "The configuration file for the current puppet application.",
      },
      :pidfile => {
          :type => :file,
          :default  => "$rundir/${run_mode}.pid",
          :desc     => "The file containing the PID of a running process.
            This file is intended to be used by service management frameworks
            and monitoring systems to determine if a puppet process is still in
            the process table.",
      },
      :bindaddress => {
        :default    => "0.0.0.0",
        :desc       => "The address a listening server should bind to.",
      }
  )

  define_settings(:environment,
    :manifest => {
      :default    => nil,
      :type       => :file_or_directory,
      :desc       => "The entry-point manifest for puppet master. This can be one file
        or a directory of manifests to be evaluated in alphabetical order. Puppet manages
        this path as a directory if one exists or if the path ends with a / or \\.

        Setting a global value for `manifest` in puppet.conf is not allowed
        (but it can be overridden from them commandline). Please use
        directory environments instead. If you need to use something other than the
        environment's `manifests` directory as the main manifest, you can set
        `manifest` in environment.conf. For more info, see
        https://docs.puppetlabs.com/puppet/latest/reference/environments.html",
    },
    :modulepath => {
      :default => "",
      :type => :path,
      :desc => "The search path for modules, as a list of directories separated by the system
        path separator character. (The POSIX path separator is ':', and the
        Windows path separator is ';'.)

        Setting a global value for `modulepath` in puppet.conf is not allowed
        (but it can be overridden from the commandline). Please use
        directory environments instead. If you need to use something other than the
        default modulepath of `<ACTIVE ENVIRONMENT'S MODULES DIR>:$basemodulepath`,
        you can set `modulepath` in environment.conf. For more info, see
        https://docs.puppetlabs.com/puppet/latest/reference/environments.html",
    },
    :config_version => {
      :default    => "",
      :desc       => "How to determine the configuration version.  By default, it will be the
      time that the configuration is parsed, but you can provide a shell script to override how the
      version is determined.  The output of this script will be added to every log message in the
      reports, allowing you to correlate changes on your hosts to the source version on the server.

      Setting a global value for config_version in puppet.conf is not allowed
      (but it can be overridden from the commandline). Please set a
      per-environment value in environment.conf instead. For more info, see
      https://docs.puppetlabs.com/puppet/latest/reference/environments.html",
    }
  )

  define_settings(:master,
    :user => {
      :default    => "puppet",
      :desc       => "The user puppet master should run as.",
    },
    :group => {
      :default    => "puppet",
      :desc       => "The group puppet master should run as.",
    },
    :default_manifest => {
      :default    => "./manifests",
      :type       => :string,
      :desc       => "The default main manifest for directory environments. Any environment that
        doesn't set the `manifest` setting in its `environment.conf` file will use
        this manifest.

        This setting's value can be an absolute or relative path. An absolute path
        will make all environments default to the same main manifest; a relative
        path will allow each environment to use its own manifest, and Puppet will
        resolve the path relative to each environment's main directory.

        In either case, the path can point to a single file or to a directory of
        manifests to be evaluated in alphabetical order.",
    },
    :disable_per_environment_manifest => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether to disallow an environment-specific main manifest. When set
        to `true`, Puppet will use the manifest specified in the `default_manifest` setting
        for all environments. If an environment specifies a different main manifest in its
        `environment.conf` file, catalog requests for that environment will fail with an error.

        This setting requires `default_manifest` to be set to an absolute path.",
      :hook       => proc do |value|
        if value && !Pathname.new(Puppet[:default_manifest]).absolute?
          raise(Puppet::Settings::ValidationError,
                "The 'default_manifest' setting must be set to an absolute path when 'disable_per_environment_manifest' is true")
        end
      end,
    },
    :code => {
      :default    => "",
      :desc       => "Code to parse directly.  This is essentially only used
      by `puppet`, and should only be set if you're writing your own Puppet
      executable.",
    },
    :masterhttplog => {
      :default => "$logdir/masterhttp.log",
      :type => :file,
      :owner => "service",
      :group => "service",
      :mode => "0660",
      :create => true,
      :desc => "Where the puppet master web server saves its access log. This is
        only used when running a WEBrick puppet master. When puppet master is
        running under a Rack server like Passenger, that web server will have
        its own logging behavior."
    },
    :masterport => {
      :default    => 8140,
      :desc       => "The port for puppet master traffic. For puppet master,
      this is the port to listen on; for puppet agent, this is the port
      to make requests on. Both applications use this setting to get the port.",
    },
    :node_name => {
      :default    => "cert",
      :desc       => "How the puppet master determines the client's identity
      and sets the 'hostname', 'fqdn' and 'domain' facts for use in the manifest,
      in particular for determining which 'node' statement applies to the client.
      Possible values are 'cert' (use the subject's CN in the client's
      certificate) and 'facter' (use the hostname that the client
      reported in its facts)",
    },
    :bucketdir => {
      :default => "$vardir/bucket",
      :type => :directory,
      :mode => "0750",
      :owner => "service",
      :group => "service",
      :desc => "Where FileBucket files are stored."
    },
    :rest_authconfig => {
      :default    => "$confdir/auth.conf",
      :type       => :file,
      :desc       => "The configuration file that defines the rights to the different
      rest indirections.  This can be used as a fine-grained
      authorization system for `puppet master`.",
    },
    :ca => {
      :default    => true,
      :type       => :boolean,
      :desc       => "Whether the master should function as a certificate authority.",
    },
    :trusted_oid_mapping_file => {
      :default    => "$confdir/custom_trusted_oid_mapping.yaml",
      :type       => :file,
      :desc       => "File that provides mapping between custom SSL oids and user-friendly names"
    },
    :basemodulepath => {
      :default => "$codedir/modules#{File::PATH_SEPARATOR}/opt/puppetlabs/puppet/modules",
      :type => :path,
      :desc => "The search path for **global** modules. Should be specified as a
        list of directories separated by the system path separator character. (The
        POSIX path separator is ':', and the Windows path separator is ';'.)

        These are the modules that will be used by _all_ environments. Note that
        the `modules` directory of the active environment will have priority over
        any global directories. For more info, see
        https://docs.puppetlabs.com/puppet/latest/reference/environments.html",
    },
    :ssl_client_header => {
      :default    => "HTTP_X_CLIENT_DN",
      :desc       => "The header containing an authenticated client's SSL DN.
      This header must be set by the proxy to the authenticated client's SSL
      DN (e.g., `/CN=puppet.puppetlabs.com`).  Puppet will parse out the Common
      Name (CN) from the Distinguished Name (DN) and use the value of the CN
      field for authorization.

      Note that the name of the HTTP header gets munged by the web server
      common gateway inteface: an `HTTP_` prefix is added, dashes are converted
      to underscores, and all letters are uppercased.  Thus, to use the
      `X-Client-DN` header, this setting should be `HTTP_X_CLIENT_DN`.",
    },
    :ssl_client_verify_header => {
      :default    => "HTTP_X_CLIENT_VERIFY",
      :desc       => "The header containing the status message of the client
      verification. This header must be set by the proxy to 'SUCCESS' if the
      client successfully authenticated, and anything else otherwise.

      Note that the name of the HTTP header gets munged by the web server
      common gateway inteface: an `HTTP_` prefix is added, dashes are converted
      to underscores, and all letters are uppercased.  Thus, to use the
      `X-Client-Verify` header, this setting should be
      `HTTP_X_CLIENT_VERIFY`.",
    },
    # To make sure this directory is created before we try to use it on the server, we need
    # it to be in the server section (#1138).
    :yamldir => {
      :default => "$vardir/yaml",
      :type => :directory,
      :owner => "service",
      :group => "service",
      :mode => "0750",
      :desc => "The directory in which YAML data is stored, usually in a subdirectory."},
    :server_datadir => {
      :default => "$vardir/server_data",
      :type => :directory,
      :owner => "service",
      :group => "service",
      :mode => "0750",
      :desc => "The directory in which serialized data is stored, usually in a subdirectory."},
    :reports => {
      :default    => "store",
      :desc       => "The list of report handlers to use. When using multiple report handlers,
        their names should be comma-separated, with whitespace allowed. (For example,
        `reports = http, store`.)

        This setting is relevant to puppet master and puppet apply. The puppet
        master will call these report handlers with the reports it receives from
        agent nodes, and puppet apply will call them with its own report. (In
        all cases, the node applying the catalog must have `report = true`.)

        See the report reference for information on the built-in report
        handlers; custom report handlers can also be loaded from modules.
        (Report handlers are loaded from the lib directory, at
        `puppet/reports/NAME.rb`.)",
    },
    :reportdir => {
      :default => "$vardir/reports",
      :type => :directory,
      :mode => "0750",
      :owner => "service",
      :group => "service",
      :desc => "The directory in which to store reports. Each node gets
        a separate subdirectory in this directory. This setting is only
        used when the `store` report processor is enabled (see the
        `reports` setting)."},
    :reporturl => {
      :default    => "http://localhost:3000/reports/upload",
      :desc       => "The URL that reports should be forwarded to. This setting
        is only used when the `http` report processor is enabled (see the
        `reports` setting).",
    },
    :fileserverconfig => {
      :default    => "$confdir/fileserver.conf",
      :type       => :file,
      :desc       => "Where the fileserver configuration is stored.",
    },
    :strict_hostname_checking => {
      :default    => false,
      :desc       => "Whether to only search for the complete
            hostname as it is in the certificate when searching for node information
            in the catalogs.",
    }
  )

  define_settings(:device,
    :devicedir =>  {
        :default  => "$vardir/devices",
        :type     => :directory,
        :mode     => "0750",
        :desc     => "The root directory of devices' $vardir.",
    },
    :deviceconfig => {
        :default  => "$confdir/device.conf",
        :desc     => "Path to the device config file for puppet device.",
    }
  )

  define_settings(:agent,
    :node_name_value => {
      :default => "$certname",
      :desc => "The explicit value used for the node name for all requests the agent
        makes to the master. WARNING: This setting is mutually exclusive with
        node_name_fact.  Changing this setting also requires changes to the default
        auth.conf configuration on the Puppet Master.  Please see
        http://links.puppetlabs.com/node_name_value for more information."
    },
    :node_name_fact => {
      :default => "",
      :desc => "The fact name used to determine the node name used for all requests the agent
        makes to the master. WARNING: This setting is mutually exclusive with
        node_name_value.  Changing this setting also requires changes to the default
        auth.conf configuration on the Puppet Master.  Please see
        http://links.puppetlabs.com/node_name_fact for more information.",
      :hook => proc do |value|
        if !value.empty? and Puppet[:node_name_value] != Puppet[:certname]
          raise "Cannot specify both the node_name_value and node_name_fact settings"
        end
      end
    },
    :statefile => {
      :default => "$statedir/state.yaml",
      :type => :file,
      :mode => "0660",
      :desc => "Where puppet agent and puppet master store state associated
        with the running configuration.  In the case of puppet master,
        this file reflects the state discovered through interacting
        with clients."
      },
    :clientyamldir => {
      :default => "$vardir/client_yaml",
      :type => :directory,
      :mode => "0750",
      :desc => "The directory in which client-side YAML data is stored."
    },
    :client_datadir => {
      :default => "$vardir/client_data",
      :type => :directory,
      :mode => "0750",
      :desc => "The directory in which serialized data is stored on the client."
    },
    :classfile => {
      :default => "$statedir/classes.txt",
      :type => :file,
      :owner => "root",
      :mode => "0640",
      :desc => "The file in which puppet agent stores a list of the classes
        associated with the retrieved configuration.  Can be loaded in
        the separate `puppet` executable using the `--loadclasses`
        option."},
    :resourcefile => {
      :default => "$statedir/resources.txt",
      :type => :file,
      :owner => "root",
      :mode => "0640",
      :desc => "The file in which puppet agent stores a list of the resources
        associated with the retrieved configuration."  },
    :puppetdlog => {
      :default => "$logdir/puppetd.log",
      :type => :file,
      :owner => "root",
      :mode => "0640",
      :desc => "The fallback log file. This is only used when the `--logdest` option
        is not specified AND Puppet is running on an operating system where both
        the POSIX syslog service and the Windows Event Log are unavailable. (Currently,
        no supported operating systems match that description.)

        Despite the name, both puppet agent and puppet master will use this file
        as the fallback logging destination.

        For control over logging destinations, see the `--logdest` command line
        option in the manual pages for puppet master, puppet agent, and puppet
        apply. You can see man pages by running `puppet <SUBCOMMAND> --help`,
        or read them online at https://docs.puppetlabs.com/puppet/latest/reference/man/."
    },
    :server => {
      :default => "puppet",
      :desc => "The puppet master server to which the puppet agent should connect."
    },
    :use_srv_records => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether the server will search for SRV records in DNS for the current domain.",
    },
    :srv_domain => {
      :default    => lambda { Puppet::Settings.domain_fact },
      :desc       => "The domain which will be queried to find the SRV records of servers to use.",
    },
    :ignoreschedules => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Boolean; whether puppet agent should ignore schedules.  This is useful
      for initial puppet agent runs.",
    },
    :default_schedules => {
      :default    => true,
      :type       => :boolean,
      :desc       => "Boolean; whether to generate the default schedule resources. Setting this to
      false is useful for keeping external report processors clean of skipped schedule resources.",
    },
    :noop => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether to apply catalogs in noop mode, which allows Puppet to
        partially simulate a normal run. This setting affects puppet agent and
        puppet apply.

        When running in noop mode, Puppet will check whether each resource is in sync,
        like it does when running normally. However, if a resource attribute is not in
        the desired state (as declared in the catalog), Puppet will take no
        action, and will instead report the changes it _would_ have made. These
        simulated changes will appear in the report sent to the puppet master, or
        be shown on the console if running puppet agent or puppet apply in the
        foreground. The simulated changes will not send refresh events to any
        subscribing or notified resources, although Puppet will log that a refresh
        event _would_ have been sent.

        **Important note:**
        [The `noop` metaparameter](https://docs.puppetlabs.com/puppet/latest/reference/metaparameter.html#noop)
        allows you to apply individual resources in noop mode, and will override
        the global value of the `noop` setting. This means a resource with
        `noop => false` _will_ be changed if necessary, even when running puppet
        agent with `noop = true` or `--noop`. (Conversely, a resource with
        `noop => true` will only be simulated, even when noop mode is globally disabled.)",
    },
    :runinterval => {
      :default  => "30m",
      :type     => :duration,
      :desc     => "How often puppet agent applies the catalog.
          Note that a runinterval of 0 means \"run continuously\" rather than
          \"never run.\" If you want puppet agent to never run, you should start
          it with the `--no-client` option. #{AS_DURATION}",
    },
    :ca_server => {
      :default    => "$server",
      :desc       => "The server to use for certificate
      authority requests.  It's a separate server because it cannot
      and does not need to horizontally scale.",
    },
    :ca_port => {
      :default    => "$masterport",
      :desc       => "The port to use for the certificate authority.",
    },
    :preferred_serialization_format => {
      :default    => "pson",
      :desc       => "The preferred means of serializing
      ruby instances for passing over the wire.  This won't guarantee that all
      instances will be serialized using this method, since not all classes
      can be guaranteed to support this format, but it will be used for all
      classes that support it.",
    },
    :agent_catalog_run_lockfile => {
      :default    => "$statedir/agent_catalog_run.lock",
      :type       => :string, # (#2888) Ensure this file is not added to the settings catalog.
      :desc       => "A lock file to indicate that a puppet agent catalog run is currently in progress.
        The file contains the pid of the process that holds the lock on the catalog run.",
    },
    :agent_disabled_lockfile => {
        :default    => "$statedir/agent_disabled.lock",
        :type       => :file,
        :desc       => "A lock file to indicate that puppet agent runs have been administratively
          disabled.  File contains a JSON object with state information.",
    },
    :usecacheonfailure => {
      :default    => true,
      :type       => :boolean,
      :desc       => "Whether to use the cached configuration when the remote
        configuration will not compile.  This option is useful for testing
        new configurations, where you want to fix the broken configuration
        rather than reverting to a known-good one.",
    },
    :use_cached_catalog => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether to only use the cached catalog rather than compiling a new catalog
        on every run.  Puppet can be run with this enabled by default and then selectively
        disabled when a recompile is desired.",
    },
    :ignoremissingtypes => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Skip searching for classes and definitions that were missing during a
        prior compilation. The list of missing objects is maintained per-environment and
        persists until the environment is cleared or the master is restarted.",
    },
    :ignorecache => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Ignore cache and always recompile the configuration.  This is
        useful for testing new configurations, where the local cache may in
        fact be stale even if the timestamps are up to date - if the facts
        change or if the server changes.",
    },
    :splaylimit => {
      :default    => "$runinterval",
      :type       => :duration,
      :desc       => "The maximum time to delay before runs.  Defaults to being the same as the
        run interval. #{AS_DURATION}",
    },
    :splay => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether to sleep for a pseudo-random (but consistent) amount of time before
        a run.

        For example, without `splay` enabled, your agent checks in every 30
        minutes at :01 and :31 past the hour. After enabling `splay`, the agent
        will wait the pseudorandom sleep time, say eight minutes, and then check
        in every 30 minutes, at :09 and :39 after the hour. If you restart the
        same agent at 12:45 PM, it will wait its eight minutes, and check in at
        12:52 PM, and every 30 minutes after that, at 1:22 PM, 1:52 PM, and so
        on. Other agents will have different sleep times, and so will check in
        at different times even if they are all restarted at the same time.",
    },
    :clientbucketdir => {
      :default  => "$vardir/clientbucket",
      :type     => :directory,
      :mode     => "0750",
      :desc     => "Where FileBucket files are stored locally."
    },
    :configtimeout => {
      :default  => "2m",
      :type     => :duration,
      :desc     => "How long the client should wait for the configuration to be retrieved
        before considering it a failure. This setting is deprecated and has been replaced
        by http_connect_timeout and http_read_timeout.
        #{AS_DURATION}",
      :deprecated => :completely,
      :hook       => proc do |value|
        Puppet[:http_connect_timeout] = value
        Puppet[:http_read_timeout]    = value
      end
    },
    :report_server => {
      :default  => "$server",
      :desc     => "The server to send transaction reports to.",
    },
    :report_port => {
      :default  => "$masterport",
      :desc     => "The port to communicate with the report_server.",
    },
    :report => {
      :default  => true,
      :type     => :boolean,
      :desc     => "Whether to send reports after every transaction.",
    },
    :lastrunfile =>  {
      :default  => "$statedir/last_run_summary.yaml",
      :type     => :file,
      :mode     => "0644",
      :desc     => "Where puppet agent stores the last run report summary in yaml format."
    },
    :lastrunreport =>  {
      :default  => "$statedir/last_run_report.yaml",
      :type     => :file,
      :mode     => "0640",
      :desc     => "Where puppet agent stores the last run report in yaml format."
    },
    :graph => {
      :default  => false,
      :type     => :boolean,
      :desc     => "Whether to create .dot graph files, which let you visualize the
        dependency and containment relationships in Puppet's catalog. You
        can load and view these files with tools like
        [OmniGraffle](http://www.omnigroup.com/applications/omnigraffle/) (OS X)
        or [graphviz](http://www.graphviz.org/) (multi-platform).

        Graph files are created when _applying_ a catalog, so this setting
        should be used on nodes running `puppet agent` or `puppet apply`.

        The `graphdir` setting determines where Puppet will save graphs. Note
        that we don't save graphs for historical runs; Puppet will replace the
        previous .dot files with new ones every time it applies a catalog.

        See your graphing software's documentation for details on opening .dot
        files. If you're using GraphViz's `dot` command, you can do a quick PNG
        render with `dot -Tpng <DOT FILE> -o <OUTPUT FILE>`.",
    },
    :graphdir => {
      :default    => "$statedir/graphs",
      :type       => :directory,
      :desc       => "Where to save .dot-format graphs (when the `graph` setting is enabled).",
    },
    :waitforcert => {
      :default  => "2m",
      :type     => :duration,
      :desc     => "How frequently puppet agent should ask for a signed certificate.

      When starting for the first time, puppet agent will submit a certificate
      signing request (CSR) to the server named in the `ca_server` setting
      (usually the puppet master); this may be autosigned, or may need to be
      approved by a human, depending on the CA server's configuration.

      Puppet agent cannot apply configurations until its approved certificate is
      available. Since the certificate may or may not be available immediately,
      puppet agent will repeatedly try to fetch it at this interval. You can
      turn off waiting for certificates by specifying a time of 0, in which case
      puppet agent will exit if it cannot get a cert.
      #{AS_DURATION}",
    },
    :ordering => {
      :type => :enum,
      :values => ["manifest", "title-hash", "random"],
      :default => "manifest",
      :desc => "How unrelated resources should be ordered when applying a catalog.
      Allowed values are `title-hash`, `manifest`, and `random`. This
      setting affects puppet agent and puppet apply, but not puppet master.

      * `manifest` (the default) will use the order in which the resources were
        declared in their manifest files.
      * `title-hash` (the default in 3.x) will order resources randomly, but
        will use the same order across runs and across nodes. It is only of
        value if you're migrating from 3.x and have errors running with
        `manifest`.
      * `random` will order resources randomly and change their order with each
        run. This can work like a fuzzer for shaking out undeclared dependencies.

      Regardless of this setting's value, Puppet will always obey explicit
      dependencies set with the before/require/notify/subscribe metaparameters
      and the `->`/`~>` chaining arrows; this setting only affects the relative
      ordering of _unrelated_ resources."
    }
  )

  define_settings(:inspect,
    :archive_files => {
        :type     => :boolean,
        :default  => false,
        :desc     => "During an inspect run, whether to archive files whose contents are audited to a file bucket.",
    },
    :archive_file_server => {
        :default  => "$server",
        :desc     => "During an inspect run, the file bucket server to archive files to if archive_files is set.",
    }
  )

  # Plugin information.

  define_settings(
    :main,
    :plugindest => {
      :type       => :directory,
      :default    => "$libdir",
      :desc       => "Where Puppet should store plugins that it pulls down from the central
      server.",
    },
    :pluginsource => {
      :default    => "puppet:///plugins",
      :desc       => "From where to retrieve plugins.  The standard Puppet `file` type
      is used for retrieval, so anything that is a valid file source can
      be used here.",
    },
    :pluginfactdest => {
      :type     => :directory,
      :default  => "$vardir/facts.d",
      :desc     => "Where Puppet should store external facts that are being handled by pluginsync",
    },
    :pluginfactsource => {
      :default  => "puppet:///pluginfacts",
      :desc     => "Where to retrieve external facts for pluginsync",
    },
    :pluginsync => {
      :default    => true,
      :type       => :boolean,
      :desc       => "Whether plugins should be synced with the central server. This setting is
        deprecated.",
      :hook => proc { |value|
        Puppet.deprecation_warning "Setting 'pluginsync' is deprecated."
      }
    },

    :pluginsignore => {
        :default  => ".svn CVS .git",
        :desc     => "What files to ignore when pulling down plugins.",
    }
  )

  # Central fact information.

    define_settings(
    :main,
    :factpath => {
      :type     => :path,
      :default  => "$vardir/lib/facter#{File::PATH_SEPARATOR}$vardir/facts",
      :desc     => "Where Puppet should look for facts.  Multiple directories should
        be separated by the system path separator character. (The POSIX path
        separator is ':', and the Windows path separator is ';'.)",

      :call_hook => :on_initialize_and_write, # Call our hook with the default value, so we always get the value added to facter.
      :hook => proc do |value|
        paths = value.split(File::PATH_SEPARATOR)
        Facter.search(*paths)
      end
    }
  )

  define_settings(
    :transaction,
    :tags => {
      :default    => "",
      :desc       => "Tags to use to find resources.  If this is set, then
        only resources tagged with the specified tags will be applied.
        Values must be comma-separated.",
    },
    :skip_tags => {
      :default    => "",
      :desc       => "Tags to use to filter resources.  If this is set, then
        only resources not tagged with the specified tags will be applied.
        Values must be comma-separated.",
    },
    :evaltrace => {
      :default    => false,
      :type       => :boolean,
      :desc       => "Whether each resource should log when it is
        being evaluated.  This allows you to interactively see exactly
        what is being done.",
    },
    :summarize => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Whether to print a transaction summary.",
    }
  )

    define_settings(
    :main,
    :external_nodes => {
        :default  => "none",
        :desc     => "An external command that can produce node information.  The command's output
          must be a YAML dump of a hash, and that hash must have a `classes` key and/or
          a `parameters` key, where `classes` is an array or hash and
          `parameters` is a hash.  For unknown nodes, the command should
          exit with a non-zero exit code.

          This command makes it straightforward to store your node mapping
          information in other data sources like databases.",
    }
    )

        define_settings(
        :ldap,
    :ldapssl => {
      :default  => false,
      :type   => :boolean,
      :desc   => "Whether SSL should be used when searching for nodes.
        Defaults to false because SSL usually requires certificates
        to be set up on the client side.",
    },
    :ldaptls => {
      :default  => false,
      :type     => :boolean,
      :desc     => "Whether TLS should be used when searching for nodes.
        Defaults to false because TLS usually requires certificates
        to be set up on the client side.",
    },
    :ldapserver => {
      :default  => "ldap",
      :desc     => "The LDAP server.  Only used if `node_terminus` is set to `ldap`.",
    },
    :ldapport => {
      :default  => 389,
      :desc     => "The LDAP port.  Only used if `node_terminus` is set to `ldap`.",
    },

    :ldapstring => {
      :default  => "(&(objectclass=puppetClient)(cn=%s))",
      :desc     => "The search string used to find an LDAP node.",
    },
    :ldapclassattrs => {
      :default  => "puppetclass",
      :desc     => "The LDAP attributes to use to define Puppet classes.  Values
        should be comma-separated.",
    },
    :ldapstackedattrs => {
      :default  => "puppetvar",
      :desc     => "The LDAP attributes that should be stacked to arrays by adding
        the values in all hierarchy elements of the tree.  Values
        should be comma-separated.",
    },
    :ldapattrs => {
      :default  => "all",
      :desc     => "The LDAP attributes to include when querying LDAP for nodes.  All
        returned attributes are set as variables in the top-level scope.
        Multiple values should be comma-separated.  The value 'all' returns
        all attributes.",
    },
    :ldapparentattr => {
      :default  => "parentnode",
      :desc     => "The attribute to use to define the parent node.",
    },
    :ldapuser => {
      :default  => "",
      :desc     => "The user to use to connect to LDAP.  Must be specified as a
        full DN.",
    },
    :ldappassword => {
      :default  => "",
      :desc     => "The password to use to connect to LDAP.",
    },
    :ldapbase => {
        :default  => "",
        :desc     => "The search base for LDAP searches.  It's impossible to provide
          a meaningful default here, although the LDAP libraries might
          have one already set.  Generally, it should be the 'ou=Hosts'
          branch under your main directory.",
    }
  )

  define_settings(:master,
    :storeconfigs => {
      :default  => false,
      :type     => :boolean,
      :desc     => "Whether to store each client's configuration, including catalogs, facts,
        and related data. This also enables the import and export of resources in
        the Puppet language - a mechanism for exchange resources between nodes.

        By default this uses the 'puppetdb' backend.

        You can adjust the backend using the storeconfigs_backend setting.",
      # Call our hook with the default value, so we always get the libdir set.
      :call_hook => :on_initialize_and_write,
      :hook => proc do |value|
        require 'puppet/node'
        require 'puppet/node/facts'
        if value
          Puppet::Resource::Catalog.indirection.cache_class = :store_configs
          Puppet.settings.override_default(:catalog_cache_terminus, :store_configs)
          Puppet::Node::Facts.indirection.cache_class = :store_configs
          Puppet::Resource.indirection.terminus_class = :store_configs
        end
      end
    },
    :storeconfigs_backend => {
      :type => :terminus,
      :default => "puppetdb",
      :desc => "Configure the backend terminus used for StoreConfigs.
        By default, this uses the PuppetDB store, which must be installed
        and configured before turning on StoreConfigs."
    }
  )

  define_settings(:parser,
   :max_errors => {
     :default => 10,
     :desc => <<-'EOT'
       Sets the max number of logged/displayed parser validation errors in case
       multiple errors have been detected. A value of 0 is the same as a value of 1; a
       minimum of one error is always raised.  The count is per manifest.
     EOT
   },
   :max_warnings => {
     :default => 10,
     :desc => <<-'EOT'
       Sets the max number of logged/displayed parser validation warnings in
       case multiple warnings have been detected. A value of 0 blocks logging of
       warnings.  The count is per manifest.
     EOT
     },
  :max_deprecations => {
    :default => 10,
    :desc => <<-'EOT'
      Sets the max number of logged/displayed parser validation deprecation
      warnings in case multiple deprecation warnings have been detected. A value of 0
      blocks the logging of deprecation warnings.  The count is per manifest.
    EOT
    },
  :strict_variables => {
    :default => false,
    :type => :boolean,
    :desc => <<-'EOT'
      Makes the parser raise errors when referencing unknown variables. (This does not affect
      referencing variables that are explicitly set to undef).
    EOT
    }
  )
  define_settings(:puppetdoc,
    :document_all => {
        :default  => false,
        :type     => :boolean,
        :desc     => "Whether to document all resources when using `puppet doc` to
          generate manifest documentation.",
    }
  )
end
