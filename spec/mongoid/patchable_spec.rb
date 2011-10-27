require 'spec_helper'
require 'mongoid'
require 'mongoid/patchable'
require 'json/patch'

class PatchableDoc
  include Mongoid::Document
  include Mongoid::Patchable
  field :foo, type: Array
  field :bar, type: Hash
  field :baz, type: Integer
end

describe Mongoid::Patchable do
  subject { PatchableDoc.new }

  describe "#apply_patch" do
    it 'should call process_add' do
      subject.expects(:process_add).with(subject, subject.fields['foo'], :foo, 12345)
      subject.apply_patch(JSON::Patch.new([{ 'add' => '/foo', 'value' => 12345}])).should be_true
    end

    it 'should call process_replace' do
      subject.expects(:process_replace).with(subject, subject.fields['foo'], :foo, 12345)
      subject.apply_patch(JSON::Patch.new([{ 'replace' => '/foo', 'value' => 12345}])).should be_true
    end

    it 'should call process_remove' do
      subject.expects(:process_remove).with(subject, subject.fields['foo'], :foo, nil)
      subject.apply_patch(JSON::Patch.new([{ 'remove' => '/foo'}])).should be_true
    end
  end

  describe "#process_add" do
    it "should add an element to an array" do
      subject.expects(:add_to_set).with(:foo, 12345)
      subject.send(:process_add, subject, subject.fields['foo'], :foo, 12345)
    end

    it "should add an element to a hash" do
      subject.expects(:save)
      subject.send(:process_add, subject, subject.fields['bar'], :bar, "rilo=kiley")
      subject.bar.should == {'rilo' => 'kiley'}
    end

    it "should set a scalar" do
      subject.expects(:set).with(:baz, 12345)
      subject.send(:process_add, subject, subject.fields['baz'], :baz, 12345)
    end
  end

  describe "#process_replace" do
    it "should replace an element in an array" do
      subject.expects(:add_to_set).with(:foo, 12345)
      subject.send(:process_replace, subject, subject.fields['foo'], :foo, 12345)
    end

    it "should replace an element in a hash" do
      subject.bar = {'rilo' => 'yelik'}
      subject.expects(:save)
      subject.send(:process_replace, subject, subject.fields['bar'], :bar, "rilo=kiley")
      subject.bar.should == {'rilo' => 'kiley'}
    end

    it "should replace a scalar" do
      subject.baz = 54321
      subject.expects(:set).with(:baz, 12345)
      subject.send(:process_replace, subject, subject.fields['baz'], :baz, 12345)
    end
  end

  describe "#process_remove" do
    it "should remove an element from an array" do
      subject.expects(:pull_all).with(:foo, [12345])
      subject.send(:process_remove, subject, subject.fields['foo'], :foo, 12345)
    end

    it "should remove an element from a hash" do
      subject.bar = {'rilo' => 'kiley'}
      subject.expects(:save)
      subject.send(:process_remove, subject, subject.fields['bar'], :bar, "rilo")
      subject.bar.should == {}
    end

    it "should nil a scalar" do
      subject.baz = 54321
      subject.expects(:set).with(:baz, nil)
      subject.send(:process_remove, subject, subject.fields['baz'], :baz)
    end
  end

  describe "#destructure_hash_value" do
    it "should return array of key and value" do
      subject.send(:destructure_hash_value, "foo=bar").should == ['foo', 'bar']
    end

    it "should return removed square brackets from key and array from csv string" do
      subject.send(:destructure_hash_value, "foo[]=bar,baz").should == ['foo', ['bar', 'baz']]
    end
  end
end
