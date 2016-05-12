#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/pops'

# relative to this spec file (./) does not work as this file is loaded by rspec
require File.join(File.dirname(__FILE__), '/parser_rspec_helper')

describe "egrammar parsing function calls" do
  include ParserRspecHelper

  context "When parsing calls as statements" do
    context "in top level scope" do
      it "foo()" do
        expect(dump(parse("foo()"))).to eq("(invoke foo)")
      end

      it "notice bar" do
        expect(dump(parse("notice bar"))).to eq("(invoke notice bar)")
      end

      it "notice(bar)" do
        expect(dump(parse("notice bar"))).to eq("(invoke notice bar)")
      end

      it "foo(bar)" do
        expect(dump(parse("foo(bar)"))).to eq("(invoke foo bar)")
      end

      it "notice {a=>2}" do
        expect(dump(parse("notice {a => 2}"))).to eq("(invoke notice ({} ('a' 2)))")
      end

      it "foo(bar,)" do
        expect(dump(parse("foo(bar,)"))).to eq("(invoke foo bar)")
      end

      it "foo(bar, fum,)" do
        expect(dump(parse("foo(bar,fum,)"))).to eq("(invoke foo bar fum)")
      end

      it "notice fqdn_rand(30)" do
        expect(dump(parse("notice fqdn_rand(30)"))).to eq('(invoke notice (call fqdn_rand 30))')
      end

      it "notice type(42)" do
        expect(dump(parse("notice type(42)"))).to eq('(invoke notice (call type 42))')
      end
    end

    context "in nested scopes" do
      it "if true { foo() }" do
        expect(dump(parse("if true {foo()}"))).to eq("(if true\n  (then (invoke foo)))")
      end

      it "if true { notice bar}" do
        expect(dump(parse("if true {notice bar}"))).to eq("(if true\n  (then (invoke notice bar)))")
      end
    end
  end

  context "When parsing calls as expressions" do
    it "$a = foo()" do
      expect(dump(parse("$a = foo()"))).to eq("(= $a (call foo))")
    end

    it "$a = foo(bar)" do
      expect(dump(parse("$a = foo()"))).to eq("(= $a (call foo))")
    end

    # For egrammar where a bare word can be a "statement"
    it "$a = foo bar # illegal, must have parentheses" do
      expect(dump(parse("$a = foo bar"))).to eq("(block\n  (= $a foo)\n  bar\n)")
    end

    context "in nested scopes" do
      it "if true { $a = foo() }" do
        expect(dump(parse("if true { $a = foo()}"))).to eq("(if true\n  (then (= $a (call foo))))")
      end

      it "if true { $a= foo(bar)}" do
        expect(dump(parse("if true {$a = foo(bar)}"))).to eq("(if true\n  (then (= $a (call foo bar))))")
      end
    end
  end

  context "When parsing method calls" do
    it "$a.foo" do
      expect(dump(parse("$a.foo"))).to eq("(call-method (. $a foo))")
    end

    it "$a.foo || { }" do
      expect(dump(parse("$a.foo || { }"))).to eq("(call-method (. $a foo) (lambda ()))")
    end

    it "$a.foo |$x| { }" do
      expect(dump(parse("$a.foo |$x|{ }"))).to eq("(call-method (. $a foo) (lambda (parameters x) ()))")
    end

    it "$a.foo |$x|{ }" do
      expect(dump(parse("$a.foo |$x|{ $b = $x}"))).to eq([
        "(call-method (. $a foo) (lambda (parameters x) (block",
        "  (= $b $x)",
        ")))"
        ].join("\n"))
    end
  end

  context "When parsing an illegal argument list" do
    it "raises an error if argument list is not for a call" do
      expect do
        parse("$a  = 10, 3")
      end.to raise_error(/illegal comma/)
    end

    it "raises an error if argument list is for a potential call not allowed without parentheses" do
      expect do
        parse("foo 10, 3")
      end.to raise_error(/attempt to pass argument list to the function 'foo' which cannot be called without parentheses/)
    end

    it "does no raise an error for an argument list to an allowed call" do
      expect do
        parse("notice 10, 3")
      end.to_not raise_error()
    end
  end
end
