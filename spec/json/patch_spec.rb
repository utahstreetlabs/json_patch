require 'spec_helper'
require 'ostruct'

def os(a); OpenStruct.new(a) end

describe JSON::Patch do
  let(:hunk) { { 'add' => '/foo/bar', 'value' => 'hams'} }
  subject {JSON::Patch.new([hunk])}

  describe '#initialize' do
    its(:hunks) { should eq([JSON::Hunk.new(hunk)])}
  end

  describe '#apply_to' do
    let(:obj) { os(:foo => 1, :bar => os(:baz => 2)) }
    it 'should call apply_patch on the target' do
      obj.should_receive(:apply_patch).with(subject).and_return(true)
      subject.apply_to(obj).should == true
    end
  end
end

describe JSON::Hunk do
  subject {JSON::Hunk.new('add' => '/foo/bar', 'value' => 'hams')}

  describe "#initialize" do
    its(:op) { should eq(:add)}
    its(:path) { should eq([:foo, :bar])}
    its(:value) { should eq('hams')}
  end

  describe '#path=' do
    it 'should split paths' do
      subject.path = '/foo/bar'
      subject.path.should == [:foo, :bar]
    end

    it 'should set paths to an empty list when given nil' do
      subject.path = nil
      subject.path.should == []
    end

    it 'should raise an argument error if path without starting slash is passed' do
      lambda { subject.path = 'foo/bar' }.should raise_error(ArgumentError)
    end
  end

  describe '#resolve_path' do
    let(:obj) { os(:foo => 1, :bar => os(:baz => 2)) }
    it "should resolve paths" do
      JSON::Hunk.new('add' => '/foo').resolve_path(obj).should == [obj, :foo]
      JSON::Hunk.new('add' => '/bar/baz').resolve_path(obj).should == [obj.bar, :baz]
    end
  end
end
