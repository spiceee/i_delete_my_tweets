require 'helper'

describe IDeleteMyTweets::Ascii do
  subject(:dummy) {
    stub_const("IDeleteMyTweets::Foo", dummy_class).new
  }

  let(:dummy_class) { Class.new { include IDeleteMyTweets::Ascii } }

  describe '#show_face' do
    it "returns a table with a summary of the delete run" do
      expect(dummy.show_face).to match "@@@@@"
    end
  end
end
