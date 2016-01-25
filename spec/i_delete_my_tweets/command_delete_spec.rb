describe IDeleteMyTweets::CommandDelete do
  subject(:cli) {
    described_class.new
  }

  let(:api) {
    instance_double(IDeleteMyTweets::Api, traverse_api!: 'delete', traverse_csv!: 'delete', config: config)
  }

  let(:config) {
    instance_double(IDeleteMyTweets::Config, to_table: '[a nice table]')
  }

  before do
    allow(cli).to receive(:config).and_return(config)
    allow(cli).to receive(:api).and_return(api)
  end

  describe "#start" do
    it "starts deleting tweets" do
      cli.start
      expect(api).to have_received(:traverse_api!)
    end
  end

  describe "#from_csv" do
    it "starts deleting tweets using csv file" do
      cli.from_csv
      expect(api).to have_received(:traverse_csv!)
    end
  end
end
