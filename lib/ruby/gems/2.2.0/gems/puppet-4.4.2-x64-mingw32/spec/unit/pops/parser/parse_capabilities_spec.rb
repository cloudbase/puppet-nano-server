#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/pops'

# relative to this spec file (./) does not work as this file is loaded by rspec
require File.join(File.dirname(__FILE__), '/parser_rspec_helper')

describe "egrammar parsing of capability mappings" do
  include ParserRspecHelper

  before(:each) do
    with_app_management(true)
  end

  after(:each) do
    with_app_management(false)
  end

  context "when parsing 'produces'" do
    it "the ast contains produces and attributes" do
      prog = "Foo produces Sql { name => value }"
      ast = "(produces Foo Sql ((name => value)))"
      expect(dump(parse(prog))).to eq(ast)
    end

    it "optional end comma is allowed" do
      prog = "Foo produces Sql { name => value, }"
      ast = "(produces Foo Sql ((name => value)))"
      expect(dump(parse(prog))).to eq(ast)
    end
  end

  context "when parsing 'consumes'" do
    it "the ast contains consumes and attributes" do
      prog = "Foo consumes Sql { name => value }"
      ast = "(consumes Foo Sql ((name => value)))"
      expect(dump(parse(prog))).to eq(ast)
    end

    it "optional end comma is allowed" do
      prog = "Foo consumes Sql { name => value, }"
      ast = "(consumes Foo Sql ((name => value)))"
      expect(dump(parse(prog))).to eq(ast)
    end

  end
end
