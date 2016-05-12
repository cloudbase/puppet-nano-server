require 'spec_helper'
require 'puppet_spec/files'
require 'puppet_spec/compiler'

require 'puppet/pops'
require 'puppet/loaders'

describe 'loader helper classes' do
  it 'NamedEntry holds values and is frozen' do
    ne = Puppet::Pops::Loader::Loader::NamedEntry.new('name', 'value', 'origin')
    expect(ne.frozen?).to be_truthy
    expect(ne.typed_name).to eql('name')
    expect(ne.origin).to eq('origin')
    expect(ne.value).to eq('value')
  end

  it 'TypedName holds values and is frozen' do
    tn = Puppet::Pops::Loader::Loader::TypedName.new(:function, '::foo::bar')
    expect(tn.frozen?).to be_truthy
    expect(tn.type).to eq(:function)
    expect(tn.name_parts).to eq(['foo', 'bar'])
    expect(tn.name).to eq('foo::bar')
    expect(tn.qualified?).to be_truthy
  end
end

describe 'loaders' do
  include PuppetSpec::Files
  include PuppetSpec::Compiler

  let(:module_without_metadata) { File.join(config_dir('wo_metadata_module'), 'modules') }
  let(:module_without_lib) { File.join(config_dir('module_no_lib'), 'modules') }
  let(:mix_4x_and_3x_functions) { config_dir('mix_4x_and_3x_functions') }
  let(:module_with_metadata) { File.join(config_dir('single_module'), 'modules') }
  let(:dependent_modules_with_metadata) { config_dir('dependent_modules_with_metadata') }
  let(:user_metadata_path) { File.join(dependent_modules_with_metadata, 'modules/user/metadata.json') }

  let(:empty_test_env) { environment_for() }

  # Loaders caches the puppet_system_loader, must reset between tests
  before(:each) { Puppet::Pops::Loaders.clear() }

  it 'creates a puppet_system loader' do
    loaders = Puppet::Pops::Loaders.new(empty_test_env)
    expect(loaders.puppet_system_loader()).to be_a(Puppet::Pops::Loader::ModuleLoaders::FileBased)
  end

  it 'creates an environment loader' do
    loaders = Puppet::Pops::Loaders.new(empty_test_env)

    expect(loaders.public_environment_loader()).to be_a(Puppet::Pops::Loader::SimpleEnvironmentLoader)
    expect(loaders.public_environment_loader().to_s).to eql("(SimpleEnvironmentLoader 'environment:*test*')")
    expect(loaders.private_environment_loader()).to be_a(Puppet::Pops::Loader::DependencyLoader)
    expect(loaders.private_environment_loader().to_s).to eql("(DependencyLoader 'environment' [])")
  end

  context 'when loading from a module' do
    it 'loads a ruby function using a qualified or unqualified name' do
      loaders = Puppet::Pops::Loaders.new(environment_for(module_with_metadata))
      modulea_loader = loaders.public_loader_for_module('modulea')

      unqualified_function = modulea_loader.load_typed(typed_name(:function, 'rb_func_a')).value
      qualified_function = modulea_loader.load_typed(typed_name(:function, 'modulea::rb_func_a')).value

      expect(unqualified_function).to be_a(Puppet::Functions::Function)
      expect(qualified_function).to be_a(Puppet::Functions::Function)
      expect(unqualified_function.class.name).to eq('rb_func_a')
      expect(qualified_function.class.name).to eq('modulea::rb_func_a')
    end

    it 'loads a puppet function using a qualified name in module' do
      loaders = Puppet::Pops::Loaders.new(environment_for(module_with_metadata))
      modulea_loader = loaders.public_loader_for_module('modulea')

      qualified_function = modulea_loader.load_typed(typed_name(:function, 'modulea::hello')).value

      expect(qualified_function).to be_a(Puppet::Functions::Function)
      expect(qualified_function.class.name).to eq('modulea::hello')
    end

    it 'loads a puppet function from a module without a lib directory' do
      loaders = Puppet::Pops::Loaders.new(environment_for(module_without_lib))
      modulea_loader = loaders.public_loader_for_module('modulea')

      qualified_function = modulea_loader.load_typed(typed_name(:function, 'modulea::hello')).value

      expect(qualified_function).to be_a(Puppet::Functions::Function)
      expect(qualified_function.class.name).to eq('modulea::hello')
    end

    it 'loads a puppet function in a sub namespace of module' do
      loaders = Puppet::Pops::Loaders.new(environment_for(module_with_metadata))
      modulea_loader = loaders.public_loader_for_module('modulea')

      qualified_function = modulea_loader.load_typed(typed_name(:function, 'modulea::subspace::hello')).value

      expect(qualified_function).to be_a(Puppet::Functions::Function)
      expect(qualified_function.class.name).to eq('modulea::subspace::hello')
    end

    it 'loader does not add namespace if not given' do
      loaders = Puppet::Pops::Loaders.new(environment_for(module_without_metadata))

      moduleb_loader = loaders.public_loader_for_module('moduleb')

      expect(moduleb_loader.load_typed(typed_name(:function, 'rb_func_b'))).to be_nil
    end

    it 'loader allows loading a function more than once' do
      File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns ''

      env = environment_for(File.join(dependent_modules_with_metadata, 'modules'))
      loaders = Puppet::Pops::Loaders.new(env)

      moduleb_loader = loaders.private_loader_for_module('user')
      function = moduleb_loader.load_typed(typed_name(:function, 'user::caller')).value
      expect(function.call({})).to eql("usee::callee() was told 'passed value' + I am user::caller()")

      function = moduleb_loader.load_typed(typed_name(:function, 'user::caller')).value
      expect(function.call({})).to eql("usee::callee() was told 'passed value' + I am user::caller()")
    end
  end

  context 'when loading from a module with metadata' do
    let(:env) { environment_for(File.join(dependent_modules_with_metadata, 'modules')) }
    let(:scope) { Puppet::Parser::Compiler.new(Puppet::Node.new("test", :environment => env)).newscope(nil) }

    let(:environmentpath) { my_fixture_dir }
    let(:node) { Puppet::Node.new('test', :facts => Puppet::Node::Facts.new('facts', {}), :environment => 'dependent_modules_with_metadata') }
    let(:compiler) { Puppet::Parser::Compiler.new(node) }

    let(:user_metadata) {
      {
        'name' => 'test-user',
        'author' =>  'test',
        'description' =>  '',
        'license' =>  '',
        'source' =>  '',
        'version' =>  '1.0.0',
        'dependencies' =>  []
      }
    }

    def compile_and_get_notifications(code)
      Puppet[:code] = code
      catalog = block_given? ? compiler.compile { |catalog| yield(compiler.topscope); catalog } : compiler.compile
      catalog.resources.map(&:ref).select { |r| r.start_with?('Notify[') }.map { |r| r[7..-2] }
    end

    around(:each) do |example|
      # Initialize settings to get a full compile as close as possible to a real
      # environment load
      Puppet.settings.initialize_global_settings

      # Initialize loaders based on the environmentpath. It does not work to
      # just set the setting environmentpath for some reason - this achieves the same:
      # - first a loader is created, loading directory environments from the fixture (there is
      # one environment, 'sample', which will be loaded since the node references this
      # environment by name).
      # - secondly, the created env loader is set as 'environments' in the puppet context.
      #
      environments = Puppet::Environments::Directories.new(environmentpath, [])
      Puppet.override(:environments => environments) do
        example.run
      end
    end

    it 'all dependent modules are visible' do
      File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => [ { 'name' => 'test-usee'}, { 'name' => 'test-usee2'} ]).to_pson
      loaders = Puppet::Pops::Loaders.new(env)

      moduleb_loader = loaders.private_loader_for_module('user')
      function = moduleb_loader.load_typed(typed_name(:function, 'user::caller')).value
      expect(function.call({})).to eql("usee::callee() was told 'passed value' + I am user::caller()")

      function = moduleb_loader.load_typed(typed_name(:function, 'user::caller2')).value
      expect(function.call({})).to eql("usee2::callee() was told 'passed value' + I am user::caller2()")
    end

    [ 'outside a function', 'a puppet function declared under functions', 'a puppet function declared in init.pp', 'a ruby function'].each_with_index do |from, from_idx|
      [ {:from => from, :called => 'a puppet function declared under functions', :expects => "I'm the function usee::usee_puppet()"},
        {:from => from, :called => 'a puppet function declared in init.pp', :expects => "I'm the function usee::usee_puppet_init()"},
        {:from => from, :called => 'a ruby function', :expects => "I'm the function usee::usee_ruby()"} ].each_with_index do |desc, called_idx|
        case_number = from_idx * 3 + called_idx + 1
        it "can call #{desc[:called]} from #{desc[:from]} when dependency is present in metadata.json" do
          File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => [ { 'name' => 'test-usee'} ]).to_pson
          Puppet[:code] = "$case_number = #{case_number}\ninclude ::user"
          catalog = compiler.compile
          resource = catalog.resource('Notify', "case_#{case_number}")
          expect(resource).not_to be_nil
          expect(resource['message']).to eq(desc[:expects])
        end

        it "can call #{desc[:called]} from #{desc[:from]} when no metadata is present" do
          Puppet::Module.any_instance.expects('has_metadata?').at_least_once.returns(false)
          Puppet[:code] = "$case_number = #{case_number}\ninclude ::user"
          catalog = compiler.compile
          resource = catalog.resource('Notify', "case_#{case_number}")
          expect(resource).not_to be_nil
          expect(resource['message']).to eq(desc[:expects])
        end

        it 'can not call ruby function in a dependent module from outside a function if dependency is missing in existing metadata.json' do
          File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => []).to_pson
          Puppet[:code] = "$case_number = #{case_number}\ninclude ::user"
          expect { catalog = compiler.compile }.to raise_error(Puppet::Error, /Unknown function/)
        end
      end
    end

    it "a type can reference an autoloaded type alias from another module when dependency is present in metadata.json" do
      File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => [ { 'name' => 'test-usee'} ]).to_pson
      expect(eval_and_collect_notices(<<-CODE, node)).to eq(['ok'])
        assert_type(Usee::Zero, 0)
        notice(ok)
      CODE
    end

    it "a type can reference an autoloaded type alias from another module when no metadata is present" do
      Puppet::Module.any_instance.expects('has_metadata?').at_least_once.returns(false)
      expect(eval_and_collect_notices(<<-CODE, node)).to eq(['ok'])
        assert_type(Usee::Zero, 0)
        notice(ok)
      CODE
    end

    it "a type can reference a type alias from another module when other module has it declared in init.pp" do
      File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => [ { 'name' => 'test-usee'} ]).to_pson
      expect(eval_and_collect_notices(<<-CODE, node)).to eq(['ok'])
        include 'usee'
        assert_type(Usee::One, 1)
        notice(ok)
      CODE
    end

    it "an autoloaded type can reference an autoloaded type alias from another module when dependency is present in metadata.json" do
      File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => [ { 'name' => 'test-usee'} ]).to_pson
      expect(eval_and_collect_notices(<<-CODE, node)).to eq(['ok'])
        assert_type(User::WithUseeZero, [0])
        notice(ok)
      CODE
    end

    it "an autoloaded type can reference an autoloaded type alias from another module when other module has it declared in init.pp" do
      File.stubs(:read).with(user_metadata_path, {:encoding => 'utf-8'}).returns user_metadata.merge('dependencies' => [ { 'name' => 'test-usee'} ]).to_pson
      expect(eval_and_collect_notices(<<-CODE, node)).to eq(['ok'])
        include 'usee'
        assert_type(User::WithUseeOne, [1])
        notice(ok)
      CODE
    end
  end

  context 'when loading from a module without metadata' do
    it 'loads a ruby function with a qualified name' do
      loaders = Puppet::Pops::Loaders.new(environment_for(module_without_metadata))

      moduleb_loader = loaders.public_loader_for_module('moduleb')
      function = moduleb_loader.load_typed(typed_name(:function, 'moduleb::rb_func_b')).value

      expect(function).to be_a(Puppet::Functions::Function)
      expect(function.class.name).to eq('moduleb::rb_func_b')
    end


    it 'all other modules are visible' do
      env = environment_for(module_with_metadata, module_without_metadata)
      loaders = Puppet::Pops::Loaders.new(env)

      moduleb_loader = loaders.private_loader_for_module('moduleb')
      function = moduleb_loader.load_typed(typed_name(:function, 'moduleb::rb_func_b')).value

      expect(function.call({})).to eql("I am modulea::rb_func_a() + I am moduleb::rb_func_b()")
    end
  end

  context 'when calling' do
    let(:env) { environment_for(mix_4x_and_3x_functions) }
    let(:scope) { Puppet::Parser::Compiler.new(Puppet::Node.new("test", :environment => env)).newscope(nil) }
    let(:loader) { Puppet::Pops::Loaders.new(env).private_loader_for_module('user') }

    it 'a 3x function in dependent module can be called from a 4x function' do
      Puppet.override({ :current_environment => scope.environment, :global_scope => scope }) do
        function = loader.load_typed(typed_name(:function, 'user::caller')).value
        expect(function.call(scope)).to eql("usee::callee() got 'first' - usee::callee() got 'second'")
      end
    end

    it 'a 3x function in dependent module can be called from a puppet function' do
      Puppet.override({ :current_environment => scope.environment, :global_scope => scope }) do
        function = loader.load_typed(typed_name(:function, 'user::puppetcaller')).value
        expect(function.call(scope)).to eql("usee::callee() got 'first' - usee::callee() got 'second'")
      end
    end

    it 'a 4x function can be called from a puppet function' do
      Puppet.override({ :current_environment => scope.environment, :global_scope => scope }) do
        function = loader.load_typed(typed_name(:function, 'user::puppetcaller4')).value
        expect(function.call(scope)).to eql("usee::callee() got 'first' - usee::callee() got 'second'")
      end
    end
    it 'a puppet function can be called from a 4x function' do
      Puppet.override({ :current_environment => scope.environment, :global_scope => scope }) do
        function = loader.load_typed(typed_name(:function, 'user::callingpuppet')).value
        expect(function.call(scope)).to eql("Did you call to say you love me?")
      end
    end

    it 'a 3x function can be called with caller scope propagated from a 4x function' do
      Puppet.override({ :current_environment => scope.environment, :global_scope => scope }) do
        function = loader.load_typed(typed_name(:function, 'user::caller_ws')).value
        expect(function.call(scope, 'passed in scope')).to eql("usee::callee_ws() got 'passed in scope'")
      end
    end
  end


  def environment_for(*module_paths)
    Puppet::Node::Environment.create(:'*test*', module_paths)
  end

  def typed_name(type, name)
    Puppet::Pops::Loader::Loader::TypedName.new(type, name)
  end

  def config_dir(config_name)
    my_fixture(config_name)
  end
end
