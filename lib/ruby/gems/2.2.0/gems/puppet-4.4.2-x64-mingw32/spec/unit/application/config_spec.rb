#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/application/config'

describe Puppet::Application::Config do
  it "should be a subclass of Puppet::Application::FaceBase" do
    expect(Puppet::Application::Config.superclass).to equal(Puppet::Application::FaceBase)
  end
end
