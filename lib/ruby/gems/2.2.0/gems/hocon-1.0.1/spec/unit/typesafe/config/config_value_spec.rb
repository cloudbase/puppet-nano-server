require 'spec_helper'
require 'hocon'
require 'test_utils'

require 'hocon/impl/config_delayed_merge'
require 'hocon/impl/config_delayed_merge_object'
require 'hocon/config_error'
require 'hocon/impl/unsupported_operation_error'
require 'hocon/config_value_factory'
require 'hocon/config_render_options'



SimpleConfigOrigin = Hocon::Impl::SimpleConfigOrigin
SimpleConfigObject = Hocon::Impl::SimpleConfigObject
SimpleConfigList = Hocon::Impl::SimpleConfigList
SubstitutionExpression = Hocon::Impl::SubstitutionExpression
ConfigReference = Hocon::Impl::ConfigReference
ConfigConcatenation = Hocon::Impl::ConfigConcatenation
ConfigDelayedMerge = Hocon::Impl::ConfigDelayedMerge
ConfigDelayedMergeObject = Hocon::Impl::ConfigDelayedMergeObject
ConfigNotResolvedError = Hocon::ConfigError::ConfigNotResolvedError
UnresolvedSubstitutionError = Hocon::ConfigError::UnresolvedSubstitutionError
ConfigBugOrBrokenError = Hocon::ConfigError::ConfigBugOrBrokenError
AbstractConfigObject = Hocon::Impl::AbstractConfigObject
ConfigValueFactory = Hocon::ConfigValueFactory
ConfigFactory = Hocon::ConfigFactory
UnsupportedOperationError = Hocon::Impl::UnsupportedOperationError
ConfigNumber = Hocon::Impl::ConfigNumber
ConfigRenderOptions = Hocon::ConfigRenderOptions

describe "SimpleConfigOrigin equality" do
  context "different origins with the same name should be equal" do
    let(:a) { SimpleConfigOrigin.new_simple("foo") }
    let(:same_as_a) { SimpleConfigOrigin.new_simple("foo") }
    let(:b) { SimpleConfigOrigin.new_simple("bar") }

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "a does not equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end
  end
end

describe "ConfigInt equality" do
  context "different ConfigInts with the same value should be equal" do
    a = TestUtils.int_value(42)
    same_as_a = TestUtils.int_value(42)
    b = TestUtils.int_value(43)

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "a does not equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end
  end
end

describe "ConfigFloat equality" do
  context "different ConfigFloats with the same value should be equal" do
    a = TestUtils.double_value(3.14)
    same_as_a = TestUtils.double_value(3.14)
    b = TestUtils.double_value(4.14)

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "a does not equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end
  end
end

describe "ConfigFloat and ConfigInt equality" do
  context "different ConfigInts with the same value should be equal" do
    double_val = TestUtils.double_value(3.0)
    int_value = TestUtils.int_value(3)
    double_value_b = TestUtils.double_value(4.0)
    int_value_b = TestUtils.double_value(4)

    context "int equals double" do
      let(:first_object) { double_val }
      let(:second_object) { int_value }
      include_examples "object_equality"
    end

    context "ConfigFloat made from int equals double" do
      let(:first_object) { double_value_b }
      let(:second_object) { int_value_b }
      include_examples "object_equality"
    end

    context "3 doesn't equal 4.0" do
      let(:first_object) { int_value }
      let(:second_object) { double_value_b }
      include_examples "object_inequality"
    end

    context "4.0 doesn't equal 3.0" do
      let(:first_object) { int_value_b }
      let(:second_object) { double_val }
      include_examples "object_inequality"
    end
  end
end

describe "SimpleConfigObject equality" do
  context "SimpleConfigObjects made from hash maps" do
    a_map = TestUtils.config_map({a: 1, b: 2, c: 3})
    same_as_a_map = TestUtils.config_map({a: 1, b: 2, c: 3})
    b_map = TestUtils.config_map({a: 3, b: 4, c: 5})

    # different keys is a different case in the equals implementation
    c_map = TestUtils.config_map({x: 3, y: 4, z: 5})

    a = SimpleConfigObject.new(TestUtils.fake_origin, a_map)
    same_as_a = SimpleConfigObject.new(TestUtils.fake_origin, same_as_a_map)
    b = SimpleConfigObject.new(TestUtils.fake_origin, b_map)
    c = SimpleConfigObject.new(TestUtils.fake_origin, c_map)

    # the config for an equal object is also equal
    config = a.to_config

    context "a equals a" do
      let(:first_object) { a }
      let(:second_object) { a }
      include_examples "object_equality"
    end

    context "a equals same_as_a" do
      let(:first_object) { a }
      let(:second_object) { same_as_a }
      include_examples "object_equality"
    end

    context "b equals b" do
      let(:first_object) { b }
      let(:second_object) { b }
      include_examples "object_equality"
    end

    context "c equals c" do
      let(:first_object) { c }
      let(:second_object) { c }
      include_examples "object_equality"
    end

    context "a doesn't equal b" do
      let(:first_object) { a }
      let(:second_object) { b }
      include_examples "object_inequality"
    end

    context "a doesn't equal c" do
      let(:first_object) { a }
      let(:second_object) { c }
      include_examples "object_inequality"
    end

    context "b doesn't equal c" do
      let(:first_object) { b }
      let(:second_object) { c }
      include_examples "object_inequality"
    end

    context "a's config equals a's config" do
      let(:first_object) { config }
      let(:second_object) { config }
      include_examples "object_equality"
    end

    context "a's config equals same_as_a's config" do
      let(:first_object) { config }
      let(:second_object) { same_as_a.to_config }
      include_examples "object_equality"
    end

    context "a's config equals a's config computed again" do
      let(:first_object) { config }
      let(:second_object) { a.to_config }
      include_examples "object_equality"
    end

    context "a's config doesn't equal b's config" do
      let(:first_object) { config }
      let(:second_object) { b.to_config }
      include_examples "object_inequality"
    end

    context "a's config doesn't equal c's config" do
      let(:first_object) { config }
      let(:second_object) { c.to_config }
      include_examples "object_inequality"
    end

    context "a doesn't equal a's config" do
      let(:first_object) { a }
      let(:second_object) { config }
      include_examples "object_inequality"
    end

    context "b doesn't equal b's config" do
      let(:first_object) { b }
      let(:second_object) { b.to_config }
      include_examples "object_inequality"
    end
  end
end

describe "SimpleConfigList equality" do
  a_values = [1, 2, 3].map { |i| TestUtils.int_value(i) }
  a_list = SimpleConfigList.new(TestUtils.fake_origin, a_values)

  same_as_a_values = [1, 2, 3].map { |i| TestUtils.int_value(i) }
  same_as_a_list = SimpleConfigList.new(TestUtils.fake_origin, same_as_a_values)

  b_values = [4, 5, 6].map { |i| TestUtils.int_value(i) }
  b_list = SimpleConfigList.new(TestUtils.fake_origin, b_values)

  context "a_list equals a_list" do
    let(:first_object) { a_list }
    let(:second_object) { a_list }
    include_examples "object_equality"
  end

  context "a_list equals same_as_a_list" do
    let(:first_object) { a_list }
    let(:second_object) { same_as_a_list }
    include_examples "object_equality"
  end

  context "a_list doesn't equal b_list" do
    let(:first_object) { a_list }
    let(:second_object) { b_list }
    include_examples "object_inequality"
  end
end

describe "ConfigReference equality" do
  a = TestUtils.subst("foo")
  same_as_a = TestUtils.subst("foo")
  b = TestUtils.subst("bar")
  c = TestUtils.subst("foo", true)

  specify "testing values are of the right type" do
    expect(a).to be_instance_of(ConfigReference)
    expect(b).to be_instance_of(ConfigReference)
    expect(c).to be_instance_of(ConfigReference)
  end

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end

  context "a doesn't equal c, an optional substitution" do
    let(:first_object) { a }
    let(:second_object) { c }
    include_examples "object_inequality"
  end
end

describe "ConfigConcatenation equality" do
  a = TestUtils.subst_in_string("foo")
  same_as_a = TestUtils.subst_in_string("foo")
  b = TestUtils.subst_in_string("bar")
  c = TestUtils.subst_in_string("foo", true)

  specify "testing values are of the right type" do
    expect(a).to be_instance_of(ConfigConcatenation)
    expect(b).to be_instance_of(ConfigConcatenation)
    expect(c).to be_instance_of(ConfigConcatenation)
  end

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end

  context "a doesn't equal c, an optional substitution" do
    let(:first_object) { a }
    let(:second_object) { c }
    include_examples "object_inequality"
  end
end

describe "ConfigDelayedMerge equality" do
  s1 = TestUtils.subst("foo")
  s2 = TestUtils.subst("bar")
  a = ConfigDelayedMerge.new(TestUtils.fake_origin, [s1, s2])
  same_as_a = ConfigDelayedMerge.new(TestUtils.fake_origin, [s1, s2])
  b = ConfigDelayedMerge.new(TestUtils.fake_origin, [s2, s1])

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end
end

describe "ConfigDelayedMergeObject equality" do
  empty = SimpleConfigObject.empty
  s1 = TestUtils.subst("foo")
  s2 = TestUtils.subst("bar")
  a = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty, s1, s2])
  same_as_a = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty, s1, s2])
  b = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty, s2, s1])

  context "a equals a" do
    let(:first_object) { a }
    let(:second_object) { a }
    include_examples "object_equality"
  end

  context "a equals same_as_a" do
    let(:first_object) { a }
    let(:second_object) { same_as_a }
    include_examples "object_equality"
  end

  context "a doesn't equal b" do
    let(:first_object) { a }
    let(:second_object) { b }
    include_examples "object_inequality"
  end
end

describe "Values' to_s methods" do
  # just check that these don't throw, the exact output
  # isn't super important since it's just for debugging

  specify "to_s doesn't throw error" do
    TestUtils.int_value(10).to_s
    TestUtils.double_value(3.14).to_s
    TestUtils.string_value("hi").to_s
    TestUtils.null_value.to_s
    TestUtils.bool_value(true).to_s
    empty_object = SimpleConfigObject.empty
    empty_object.to_s

    SimpleConfigList.new(TestUtils.fake_origin, []).to_s
    TestUtils.subst("a").to_s
    TestUtils.subst_in_string("b").to_s
    dm = ConfigDelayedMerge.new(TestUtils.fake_origin, [TestUtils.subst("a"), TestUtils.subst("b")])
    dm.to_s

    dmo = ConfigDelayedMergeObject.new(TestUtils.fake_origin, [empty_object, TestUtils.subst("a"), TestUtils.subst("b")])
    dmo.to_s

    TestUtils.fake_origin.to_s
  end
end

describe "ConfigObject" do
  specify "should unwrap correctly" do
    m = SimpleConfigObject.new(TestUtils.fake_origin, TestUtils.config_map({a: 1, b: 2, c: 3}))

    expect({a: 1, b: 2, c: 3}).to eq(m.unwrapped)
  end

  specify "should implement read only map" do
    m = SimpleConfigObject.new(TestUtils.fake_origin, TestUtils.config_map({a: 1, b: 2, c: 3}))

    expect(TestUtils.int_value(1)).to eq(m[:a])
    expect(TestUtils.int_value(2)).to eq(m[:b])
    expect(TestUtils.int_value(3)).to eq(m[:c])
    expect(m[:d]).to be_nil
    # [] can take a non-string
    expect(m[[]]).to be_nil

    expect(m.has_key? :a).to be_truthy
    expect(m.has_key? :z).to be_falsey
    # has_key? can take a non-string
    expect(m.has_key? []).to be_falsey

    expect(m.has_value? TestUtils.int_value(1)).to be_truthy
    expect(m.has_value? TestUtils.int_value(10)).to be_falsey
    # has_value? can take a non-string
    expect(m.has_value? []).to be_falsey

    expect(m.empty?).to be_falsey

    expect(m.size).to eq(3)

    values = [TestUtils.int_value(1), TestUtils.int_value(2), TestUtils.int_value(3)]
    expect(values).to eq(m.values)

    keys = [:a, :b, :c]
    expect(keys).to eq(m.keys)

    expect { m["hello"] = TestUtils.int_value(41) }.to raise_error(UnsupportedOperationError)
    expect { m.delete(:a) }.to raise_error(UnsupportedOperationError)
  end
end

describe "ConfigList" do
  specify "should implement read only list" do
    values = ["a", "b", "c"].map { |i| TestUtils.string_value(i) }
    l = SimpleConfigList.new(TestUtils.fake_origin, values)

    expect(values[0]).to eq(l[0])
    expect(values[1]).to eq(l[1])
    expect(values[2]).to eq(l[2])

    expect(l.include? TestUtils.string_value("a")).to be_truthy
    expect(l.include_all?([TestUtils.string_value("a")])).to be_truthy
    expect(l.include_all?([TestUtils.string_value("b")])).to be_truthy
    expect(l.include_all?(values)).to be_truthy

    expect(l.index(values[1])).to eq(1)

    expect(l.empty?).to be_falsey

    expect(l.map { |v| v }).to eq(values.map { |v| v })

    expect(l.rindex(values[1])).to eq(1)

    expect(l.size).to eq(3)

    expect { l.push(TestUtils.int_value(3)) }.to raise_error(UnsupportedOperationError)
    expect { l << TestUtils.int_value(3) }.to raise_error(UnsupportedOperationError)
    expect { l.clear }.to raise_error(UnsupportedOperationError)
    expect { l.delete(TestUtils.int_value(2)) }.to raise_error(UnsupportedOperationError)
    expect { l.delete(1) }.to raise_error(UnsupportedOperationError)
    expect { l[0] = TestUtils.int_value(42) }.to raise_error(UnsupportedOperationError)
  end
end

describe "Objects throwing ConfigNotResolvedError" do
  context "ConfigSubstitution" do
    specify "should throw ConfigNotResolvedError" do
      expect{ TestUtils.subst("foo").value_type }.to raise_error(ConfigNotResolvedError)
      expect{ TestUtils.subst("foo").unwrapped }.to raise_error(ConfigNotResolvedError)
    end
  end

  context "ConfigDelayedMerge" do
    let(:dm) { ConfigDelayedMerge.new(TestUtils.fake_origin, [TestUtils.subst("a"), TestUtils.subst("b")]) }

    specify "should throw ConfigNotResolvedError" do
      expect{ dm.value_type }.to raise_error(ConfigNotResolvedError)
      expect{ dm.unwrapped }.to raise_error(ConfigNotResolvedError)
    end
  end

  context "ConfigDelayedMergeObject" do
    empty_object = SimpleConfigObject.empty
    objects = [empty_object, TestUtils.subst("a"), TestUtils.subst("b")]

    let(:dmo) { ConfigDelayedMergeObject.new(TestUtils.fake_origin, objects) }

    specify "should have value type of OBJECT" do
      expect(dmo.value_type).to eq(Hocon::ConfigValueType::OBJECT)
    end

    specify "should throw ConfigNotResolvedError" do
      expect{ dmo.unwrapped }.to raise_error(ConfigNotResolvedError)
      expect{ dmo["foo"] }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.has_key?(nil) }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.has_value?(nil) }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.each }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.empty? }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.keys }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.size }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.values }.to raise_error(ConfigNotResolvedError)
      expect{ dmo.to_config.get_int("foo") }.to raise_error(ConfigNotResolvedError)
    end
  end
end

describe "Round tripping numbers through parse_string" do
  specify "should get the same numbers back out" do
    # formats rounded off with E notation
    a = "132454454354353245.3254652656454808909932874873298473298472"
    # formats as 100000.0
    b = "1e6"
    # formats as 5.0E-5
    c = "0.00005"
    # formats as 1E100 (capital E)
    d = "1e100"

    object = TestUtils.parse_config("{ a : #{a}, b : #{b}, c : #{c}, d : #{d}}")
    expect([a, b, c, d]).to eq(["a", "b", "c", "d"].map { |x| object.get_string(x) })

    object2 = TestUtils.parse_config("{ a : xx #{a} yy, b : xx #{b} yy, c : xx #{c} yy, d : xx #{d} yy}")
    expected2 = [a, b, c, d].map { |x| "xx #{x} yy"}
    expect(["a", "b", "c", "d"].map { |x| object2.get_string(x) }).to eq(expected2)
  end
end



describe "AbstractConfigObject#merge_origins" do
  def o(desc, empty)
    values = {}

    if !empty
      values["hello"] = TestUtils.int_value(37)
    end

    SimpleConfigObject.new(SimpleConfigOrigin.new_simple(desc), values)
  end

  def m(*values)
    AbstractConfigObject.merge_origins(values).description
  end

  specify "should merge origins correctly" do
    # simplest case
    expect(m(o("a", false), o("b", false))).to eq("merge of a,b")

    # combine duplicate "merge of"
    expect(m(o("a", false), o("merge of x,y", false))).to eq("merge of a,x,y")
    expect(m(o("merge of a,b", false), o("merge of x,y", false))).to eq("merge of a,b,x,y")
    # ignore empty objects
    expect(m(o("foo", true), o("a", false))).to eq("a")
    # unless they are all empty, pick the first one
    expect(m(o("foo", true), o("a", true))).to eq("foo")
    # merge just one
    expect(m(o("foo", false))).to eq("foo")
    # merge three
    expect(m(o("a", false), o("b", false), o("c", false))).to eq("merge of a,b,c")
  end
end

describe "SimpleConfig#has_path?" do
  specify "should work in various contexts" do
    empty = TestUtils.parse_config("{}")

    expect(empty.has_path?("foo")).to be_falsey

    object = TestUtils.parse_config("a=null, b.c.d=11, foo=bar")

    # returns true for the non-null values
    expect(object.has_path?("foo")).to be_truthy
    expect(object.has_path?("b.c.d")).to be_truthy
    expect(object.has_path?("b.c")).to be_truthy
    expect(object.has_path?("b")).to be_truthy

    # has_path is false for null values but contains_key is true
    expect(object.root["a"]).to eq(TestUtils.null_value)
    expect(object.root.has_key?("a")).to be_truthy
    expect(object.has_path?("a")).to be_falsey

    # false for totally absent values
    expect(object.root.has_key?("notinhere")).to be_falsey
    expect(object.has_path?("notinhere")).to be_falsey

    # throws proper exceptions
    expect { empty.has_path?("a.") }.to raise_error(Hocon::ConfigError::ConfigBadPathError)
    expect { empty.has_path?("..") }.to raise_error(Hocon::ConfigError::ConfigBadPathError)
  end
end

describe "ConfigNumber::new_number" do
  specify "should create new objects correctly" do
    def n(v)
      ConfigNumber.new_number(TestUtils.fake_origin, v, nil)
    end

    expect(n(3.14).unwrapped).to eq(3.14)
    expect(n(1).unwrapped).to eq(1)
    expect(n(1).unwrapped).to eq(1.0)
  end
end

describe "Boolean conversions" do
  specify "true, yes, and on all convert to true" do
    trues = TestUtils.parse_object("{ a=true, b=yes, c=on }").to_config
    ["a", "b", "c"].map { |x| expect(trues.get_boolean(x)).to be true }

    falses = TestUtils.parse_object("{ a=false, b=no, c=off }").to_config
    ["a", "b", "c"].map { |x| expect(falses.get_boolean(x)).to be false }
  end
end

describe "SimpleConfigOrigin" do
  let(:has_filename) { SimpleConfigOrigin.new_file("foo") }
  let(:no_filename) { SimpleConfigOrigin.new_simple("bar") }
  let(:filename_with_line) { has_filename.with_line_number(3) }
  let(:no_filename_with_line) { no_filename.with_line_number(4) }

  specify "filename matches what was specified" do
    expect(has_filename.filename).to eq("foo")
    expect(filename_with_line.filename).to eq("foo")
    expect(no_filename.filename).to be nil
    expect(no_filename_with_line.filename).to be nil
  end

  specify "description matches correctly" do
    expect(has_filename.description).to eq("foo")
    expect(no_filename.description).to eq("bar")
    expect(filename_with_line.description).to eq("foo: 3")
    expect(no_filename_with_line.description).to eq("bar: 4")
  end

  specify "origins with no line number should have line number of -1" do
    expect(has_filename.line_number).to eq(-1)
    expect(no_filename.line_number).to eq(-1)
  end

  specify "line_number returns the right line number" do
    expect(filename_with_line.line_number).to eq(3)
    expect(no_filename_with_line.line_number).to eq(4)
  end

  # Note: skipping tests related to URLs since we aren't implementing that
end


describe "Config#with_only_key and with_only_path" do
  context "should keep the correct data" do
    object = TestUtils.parse_object("{ a=1, b=2, c.d.y=3, e.f.g=4, c.d.z=5 }")

    it "should keep only a" do
      expect(object.with_only_key("a")).to eq(TestUtils.parse_object("{ a=1 }"))
    end

    it "should keep only e" do
      expect(object.with_only_key("e")).to eq(TestUtils.parse_object("{ e.f.g=4 }"))
    end

    it "should keep only c.d" do
      expect(object.to_config.with_only_path("c.d").root).to eq(TestUtils.parse_object("{ c.d.y=3, c.d.z=5 }"))
    end

    it "should keep only c.d.z" do
      expect(object.to_config.with_only_path("c.d.z").root).to eq(TestUtils.parse_object("{ c.d.z=5 }"))
    end

    it "should keep nonexistent key" do
      expect(object.with_only_key("nope")).to eq(TestUtils.parse_object("{ }"))
    end

    it "should keep nonexistent path" do
      expect(object.to_config.with_only_path("q.w.e.r.t.y").root).to eq(TestUtils.parse_object("{ }"))
    end

    it "should keep only nonexistent underneath non-object" do
      expect(object.to_config.with_only_path("a.nonextistent").root).to eq(TestUtils.parse_object("{ }"))
    end

    it "should keep only nonexistent underneath nested non-object" do
      expect(object.to_config.with_only_path("c.d.z.nonexistent").root).to eq(TestUtils.parse_object("{ }"))
    end
  end

  specify "should handle unresolved correctly" do
    object = TestUtils.parse_object("{ a = {}, a=${x}, b=${y}, b=${z}, x={asf:1}, y=2, z=3 }")

    expect(object.to_config.resolve.with_only_path("a.asf").root).to eq(TestUtils.parse_object("{ a={asf:1} }"))

    TestUtils.intercept(UnresolvedSubstitutionError) do
      object.with_only_key("a").to_config.resolve
    end

    TestUtils.intercept(UnresolvedSubstitutionError) do
      object.with_only_key("b").to_config.resolve
    end

    expect(object.resolve_status).to eq(Hocon::Impl::ResolveStatus::UNRESOLVED)
    expect(object.with_only_key("z").resolve_status).to eq(Hocon::Impl::ResolveStatus::RESOLVED)
  end
end

describe "Config#without_key/path" do

  context "should remove keys correctly" do
    object = TestUtils.parse_object("{ a=1, b=2, c.d.y=3, e.f.g=4, c.d.z=5 }")

    it "should not have a" do
      expect(object.without_key("a")).to eq(TestUtils.parse_object("{ b=2, c.d.y=3, e.f.g=4, c.d.z=5 }"))
    end

    it "should not have c" do
      expect(object.without_key("c")).to eq(TestUtils.parse_object("{ a=1, b=2, e.f.g=4 }"))
    end

    it "should not have c.d" do
      expect(object.to_config.without_path("c.d").root).to eq(TestUtils.parse_object("{ a=1, b=2, e.f.g=4, c={} }"))
    end

    it "should not have c.d.z" do
      expect(object.to_config.without_path("c.d.z").root).to eq(TestUtils.parse_object("{ a=1, b=2, c.d.y=3, e.f.g=4 }"))
    end

    it "should not change without nonexistent key" do
      expect(object.without_key("nonexistent")).to eq(TestUtils.parse_object("{ a=1, b=2, c.d.y=3, e.f.g=4, c.d.z=5 }"))
    end

    it "should not change without nonexistent path" do
      expect(object.to_config.without_path("q.w.e.r.t.y").root).to eq(TestUtils.parse_object("{ a=1, b=2, c.d.y=3, e.f.g=4, c.d.z=5 }"))
    end

    it "should not change without nonexistent path with existing prefix" do
      expect(object.to_config.without_path("a.foo").root).to eq(TestUtils.parse_object("{ a=1, b=2, c.d.y=3, e.f.g=4, c.d.z=5 }"))
    end
  end
end

describe "Config#without_key/path involving unresolved" do

  specify "should handle unresolved correctly" do
    object = TestUtils.parse_object("{ a = {}, a=${x}, b=${y}, b=${z}, x={asf:1}, y=2, z=3 }")

    expect(object.to_config.resolve.without_path("a.asf").root).to eq(TestUtils.parse_object("{ a={}, b=3, x={asf:1}, y=2, z=3 }"))

    TestUtils.intercept(UnresolvedSubstitutionError) do
      object.without_key("x").to_config.resolve
    end

    TestUtils.intercept(UnresolvedSubstitutionError) do
      object.without_key("z").to_config.resolve
    end

    expect(object.resolve_status).to eq(Hocon::Impl::ResolveStatus::UNRESOLVED)
    expect(object.without_key("a").resolve_status).to eq(Hocon::Impl::ResolveStatus::UNRESOLVED)
    expect(object.without_key("a").without_key("b").resolve_status).to eq(Hocon::Impl::ResolveStatus::RESOLVED)
  end
end

describe "Config#at_path" do
  specify "works with one element" do
    v = ConfigValueFactory.from_any_ref(42)
    config = v.at_path("a")

    expect(config).to eq(TestUtils.parse_config("a=42"))
    expect(v).to eq(config.get_value("a"))
    expect(config.origin.description).to include("at_path")
  end

  specify "works with two elements" do
    v = ConfigValueFactory.from_any_ref(42)
    config = v.at_path("a.b")

    expect(config).to eq(TestUtils.parse_config("a.b=42"))
    expect(v).to eq(config.get_value("a.b"))
    expect(config.origin.description).to include("at_path")
  end

  specify "works with four elements" do
    v = ConfigValueFactory.from_any_ref(42)
    config = v.at_path("a.b.c.d")

    expect(config).to eq(TestUtils.parse_config("a.b.c.d=42"))
    expect(v).to eq(config.get_value("a.b.c.d"))
    expect(config.origin.description).to include("at_path")
  end
end

describe "Config#at_key" do
  specify "at_key works" do
    v = ConfigValueFactory.from_any_ref(42)
    config = v.at_key("a")

    expect(config).to eq(TestUtils.parse_config("a=42"))
    expect(v).to eq(config.get_value("a"))
    expect(config.origin.description).to include("at_key")
  end

  specify "works with value depth 1 from empty" do
    v = ConfigValueFactory.from_any_ref(42)
    config = ConfigFactory.empty.with_value("a", v)

    expect(config).to eq(TestUtils.parse_config("a=42"))
    expect(v).to eq(config.get_value("a"))
  end

  specify "works with value depth 2 from empty" do
    v = ConfigValueFactory.from_any_ref(42)
    config = ConfigFactory.empty.with_value("a.b", v)

    expect(config).to eq(TestUtils.parse_config("a.b=42"))
    expect(v).to eq(config.get_value("a.b"))
  end

  specify "works with value depth 3 from empty" do
    v = ConfigValueFactory.from_any_ref(42)
    config = ConfigFactory.empty.with_value("a.b.c", v)

    expect(config).to eq(TestUtils.parse_config("a.b.c=42"))
    expect(v).to eq(config.get_value("a.b.c"))
  end

  specify "with value depth 1 overwrites existing" do
    v = ConfigValueFactory.from_any_ref(47)
    old = v.at_path("a")
    config = old.with_value("a", ConfigValueFactory.from_any_ref(42))

    expect(config).to eq(TestUtils.parse_config("a=42"))
    expect(config.get_int("a")).to eq(42)
  end

  specify "with value depth 2 overwrites existing" do
    v = ConfigValueFactory.from_any_ref(47)
    old = v.at_path("a.b")
    config = old.with_value("a.b", ConfigValueFactory.from_any_ref(42))

    expect(config).to eq(TestUtils.parse_config("a.b=42"))
    expect(config.get_int("a.b")).to eq(42)
  end

  specify "with value inside existing object" do
    v = ConfigValueFactory.from_any_ref(47)
    old = v.at_path("a.c")
    config = old.with_value("a.b", ConfigValueFactory.from_any_ref(42))

    expect(config).to eq(TestUtils.parse_config("a.b=42,a.c=47"))
    expect(config.get_int("a.b")).to eq(42)
    expect(config.get_int("a.c")).to eq(47)
  end

  specify "with value build complex config" do
    v1 = ConfigValueFactory.from_any_ref(1)
    v2 = ConfigValueFactory.from_any_ref(2)
    v3 = ConfigValueFactory.from_any_ref(3)
    v4 = ConfigValueFactory.from_any_ref(4)

    config = ConfigFactory.empty.with_value("a", v1)
      .with_value("b.c", v2)
      .with_value("b.d", v3)
      .with_value("x.y.z", v4)

    expect(config).to eq(TestUtils.parse_config("a=1,b.c=2,b.d=3,x.y.z=4"))
  end
end

describe "#render" do
  context "has newlines in description" do
    v = ConfigValueFactory.from_any_ref(89, "this is a description\nwith some\nnewlines")

    list = SimpleConfigList.new(SimpleConfigOrigin.new_simple("\n5\n6\n7\n"), [v])

    conf = ConfigFactory.empty.with_value("bar", list)

    rendered = conf.root.render

    specify "rendered config should have all the lines that were added, with newlines" do
      expect(rendered).to include("is a description\n")
      expect(rendered).to include("with some\n")
      expect(rendered).to include("newlines\n")
      expect(rendered).to include("#\n")
      expect(rendered).to include("5\n")
      expect(rendered).to include("6\n")
      expect(rendered).to include("7\n")
    end

    specify "the rendered config should give back the original config" do
      parsed = ConfigFactory.parse_string(rendered)

      expect(parsed).to eq(conf)
    end
  end

  specify "should sort properly" do
    config = TestUtils.parse_config('0=a,1=b,2=c,3=d,10=e,20=f,30=g')
    rendered = config.root.render(ConfigRenderOptions.concise)

    expect(rendered).to eq('{"0":"a","1":"b","2":"c","3":"d","10":"e","20":"f","30":"g"}')
  end
end
