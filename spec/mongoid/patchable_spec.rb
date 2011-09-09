require 'spec_helper'
require 'mongoid'
require 'mongoid/patchable'
require 'json/patch'

class PatchableDoc
  include Mongoid::Document
  include Mongoid::Patchable
  field :foo, :type => Array
end

describe Mongoid::Patchable do
  subject { PatchableDoc.new }

  describe "#apply_patch" do
    it 'should add to the object' do
      subject.foo.should == nil
      subject.apply_patch(JSON::Patch.new([{ 'add' => '/foo', 'value' => 12345}])).should be_true
      subject.foo.should == [12345]
    end
  end
end
