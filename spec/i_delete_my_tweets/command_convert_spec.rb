describe IDeleteMyTweets::CommandConvert do
  subject(:cli) {
    described_class.new
  }

  describe "#convert" do
    it "calls sed to remove the non-JSON bit" do
      allow(cli).to receive(:save_to_csv).with('spec/fixtures/tweet.js').and_return(true)
      allow(cli).to receive(:js_to_json).with('spec/fixtures/tweet.js').and_return(true)
      cli.to_csv('spec/fixtures/tweet.js')
    end

    it "shows error if something goes wrong with the sed call" do
      allow(cli).to receive(:js_to_json).with('spec/fixtures/tweet.js').and_return(false)
      expect { cli.to_csv('spec/fixtures/tweet.js') }.to output(/Something went wrong with sed/).to_stdout
    end
  end
end
