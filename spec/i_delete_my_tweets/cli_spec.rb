require 'helper'

describe IDeleteMyTweets::CLI do
  subject(:cli) { instance_double(described_class, version: '0.0.1') }

  before do
    fake_class = Class.new
    stub_const("IDeleteMyTweets", fake_class, transfer_nested_constants: true)
  end

  describe "#version" do
    it "retuns the current version" do
      expect(cli.version).to eq '0.0.1'
    end
  end
end
