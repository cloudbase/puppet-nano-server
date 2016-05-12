require 'spec_helper'
require 'hiera_puppet'
require 'puppet_spec/scope'

describe 'HieraPuppet' do
  include PuppetSpec::Scope

  after(:all) do
    HieraPuppet.instance_variable_set(:@hiera, nil)
  end

  describe 'HieraPuppet#hiera_config' do
    let(:hiera_config_data) do
      { :backend => 'yaml' }
    end

    context "when the hiera_config_file exists" do
      before do
        Hiera::Config.expects(:load).returns(hiera_config_data)
        HieraPuppet.expects(:hiera_config_file).returns(true)
      end

      it "should return a configuration hash" do
        expected_results = {
          :backend => 'yaml',
          :logger  => 'puppet'
        }
        expect(HieraPuppet.send(:hiera_config)).to eq(expected_results)
      end
    end

    context "when the hiera_config_file does not exist" do
      before do
        Hiera::Config.expects(:load).never
        HieraPuppet.expects(:hiera_config_file).returns(nil)
      end

      it "should return a configuration hash" do
        expect(HieraPuppet.send(:hiera_config)).to eq({ :logger => 'puppet' })
      end
    end
  end

  describe 'HieraPuppet#hiera_config_file' do
    it "should return nil when we cannot derive the hiera config file from Puppet.settings" do
      begin
        Puppet.settings[:hiera_config] = nil
      rescue ArgumentError => detail
        raise unless detail.message =~ /unknown setting/
      end
      expect(HieraPuppet.send(:hiera_config_file)).to be_nil
    end

    it "should use Puppet.settings[:hiera_config] as the hiera config file" do
      begin
        Puppet.settings[:hiera_config] = "/dev/null/my_hiera.yaml"
      rescue ArgumentError => detail
        raise unless detail.message =~ /unknown setting/
        pending("This example does not apply to Puppet #{Puppet.version} because it does not have this setting")
      end

      Puppet::FileSystem.stubs(:exist?).with(Puppet[:hiera_config]).returns(true)
      expect(HieraPuppet.send(:hiera_config_file)).to eq(Puppet[:hiera_config])
    end

    it "should use Puppet.settings[:codedir] as the base directory when hiera_config is not set" do
      begin
        Puppet.settings[:hiera_config] = nil
      rescue ArgumentError => detail
        raise unless detail.message =~ /unknown setting/
      end
      Puppet.settings[:codedir] = "/dev/null/puppet"
      hiera_config = File.join(Puppet[:codedir], 'hiera.yaml')
      Puppet::FileSystem.stubs(:exist?).with(hiera_config).returns(true)

      expect(HieraPuppet.send(:hiera_config_file)).to eq(hiera_config)
    end
  end

  describe 'HieraPuppet#lookup' do
    let :scope do create_test_scope_for_node('foo') end

    before :each do
      Puppet[:hiera_config] = PuppetSpec::Files.tmpfile('hiera_config')
    end

    it "should return the value from Hiera" do
      Hiera.any_instance.stubs(:lookup).returns('8080')
      expect(HieraPuppet.lookup('port', nil, scope, nil, :priority)).to eq('8080')

      Hiera.any_instance.stubs(:lookup).returns(['foo', 'bar'])
      expect(HieraPuppet.lookup('ntpservers', nil, scope, nil, :array)).to eq(['foo', 'bar'])

      Hiera.any_instance.stubs(:lookup).returns({'uid' => '1000'})
      expect(HieraPuppet.lookup('user', nil, scope, nil, :hash)).to eq({'uid' => '1000'})
    end

    it "should raise a useful error when the answer is nil" do
      Hiera.any_instance.stubs(:lookup).returns(nil)
      expect do
        HieraPuppet.lookup('port', nil, scope, nil, :priority)
      end.to raise_error(Puppet::ParseError,
        /Could not find data item port in any Hiera data file and no default supplied/)
    end
  end

  describe 'HieraPuppet#parse_args' do
    it 'should return a 3 item array' do
      args = ['foo', '8080', nil, nil]
      expect(HieraPuppet.parse_args(args)).to eq(['foo', '8080', nil])
    end

    it 'should raise a useful error when no key is supplied' do
      expect { HieraPuppet.parse_args([]) }.to raise_error(Puppet::ParseError,
        /Please supply a parameter to perform a Hiera lookup/)
    end
  end
end
