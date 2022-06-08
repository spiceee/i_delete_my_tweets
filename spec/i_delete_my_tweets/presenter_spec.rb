require 'helper'

describe IDeleteMyTweets::Presenter do
  subject(:dummy) {
    stub_const("IDeleteMyTweets::Foo", dummy_class, transfer_nested_constants: true).new
  }

  let(:dummy_class) { Class.new { include IDeleteMyTweets::Presenter } }

  let(:tweet) do
    stub_const("Tweet", Class.new);
    instance_double(Tweet,
                    text: "just setting up my twttr",
                    created_at: Time.parse("5:50 PM · Mar 21, 2006"),
                    favorite_count: 178_474,
                    retweet_count: 122_400)
  end

  describe '#summary' do
    it "returns a table with a summary of the delete run" do
      expect(dummy.summary(22, 3, 2, true).headings.first.cells.first.value).to eq "Deleted"
    end
  end

  describe '#tweet_presenter' do
    it "returns a table with the deleted tweet fields" do
      expect(dummy.tweet_presenter(tweet, true).rows.first.cells.first.value).to eq "just setting up my twttr"
    end

    it "returns a dot birdie if verbose is false" do
      expect(dummy.tweet_presenter(tweet, true, verbose: false)).to eq ".🐤 "
    end
  end

  describe '#truncate' do
    it "returns a table with the deleted tweet fields" do
      expect(dummy.truncate("Please take a moment to report accounts clearly engaged in harassment. It is the only way to maintain public discourse.")).to eq "Please take a moment to report accounts ..."
    end
  end

  describe '#tweet_not_found' do
    it "returns a table with the not found tweet id" do
      expect(dummy.tweet_not_found('12345', true).rows.first.cells.first.value).to eq "12345"
    end

    it "returns a dot explosion if verbose is false" do
      expect(dummy.tweet_not_found('12345', true, verbose: false)).to eq ".💥 "
    end
  end

  describe '#to_human_time' do
    it "formats a timestamp to a shorter date" do
      expect(dummy.to_human_time(Time.parse("Wed May 04 22:48:53 +0000 2022"))).to eq "2022-05-04 22:48"
    end
  end

  describe '#to_date' do
    it "formats a timestamp to a shorter date" do
      expect(dummy.to_date("2008-03-09 00:00:00 +0000").to_s).to eq "2008-03-09"
    end
  end
end
