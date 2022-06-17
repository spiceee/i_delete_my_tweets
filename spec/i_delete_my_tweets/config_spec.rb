require 'helper'

describe IDeleteMyTweets::Config do
  subject(:config) {
    described_class.new(
      consumer_key: "foofoofoofoofoofoofoo",
      consumer_secret: '23123123213213213213',
      access_token: 'barbarbarbarbarbar',
      access_token_secret: '41232132132132132156',
      older_than: 1.week.ago,
      path_to_csv: './tweets.csv',
      fave_threshold: 1,
      rt_threshold: 1,
      with_words: nil,
      screen_name: 'filthy_billionaire'
    )
  }

  before do
    fake_class = Class.new
    stub_const("IDeleteMyTweets", fake_class, transfer_nested_constants: true)
  end

  describe '#zipped' do
    it "returns an array with all properties" do
      expect(config.zipped).to satisfy { |zip| zip.length == 10 }
    end

    it "returns tuples" do
      expect(config.zipped).to satisfy { |zip| zip.first.length == 2 }
    end

    it "obfuscates sensitive values" do
      words = Regexp.union IDeleteMyTweets::OBFUSCATE_WORDS
      expect(
        config.zipped
        .filter { |tuples| tuples.first.downcase =~ words }
        .all? { |tuples| tuples.second.include?('***') }
      ).to be_truthy
    end

    it "obfuscates all of the value if less than 4 chars" do
      words = Regexp.union IDeleteMyTweets::OBFUSCATE_WORDS
      config.consumer_key = "foo"
      expect(
        config.zipped
        .filter { |tuples| tuples.first.downcase =~ words }
        .any? { |tuples| tuples.second == '***' }
      ).to be_truthy
    end
  end

  describe '#to_table' do
    it "returns a terminal-table object" do
      expect(config.to_table.class).to eq Terminal::Table
    end
  end

  describe '#to_env' do
    it "returns a valid ENV buffer" do
      expect(config.to_env).to satisfy do |env_array|
        Dotenv::Parser.new(env_array.join("\n")).call['CONSUMER_KEY'] == 'foofoofoofoofoofoofoo'
      end
    end

    it "escapes single quotes" do
      config.consumer_key = "f'oo"
      expect(config.to_env).to satisfy do |env_array|
        Dotenv::Parser.new(env_array.join("\n")).call['CONSUMER_KEY'] == "f\\'oo"
      end
    end
  end

  describe '#empty_values' do
    it "returns an array with keys that are empty" do
      config.screen_name, config.consumer_key = nil, nil
      expect(config.empty_values).to include('SCREEN_NAME', 'CONSUMER_KEY')
    end

    it "includes with_words in the OPTIONALS list" do
      expect(IDeleteMyTweets::OPTIONALS).to include("with_words")
    end

    it "ignores empty values if the config name is in OPTIONAL" do
      config.with_words = nil
      expect(config.empty_values).to be_empty
    end
  end

  describe '#compiled_words_regex' do
    it "returns a compiled regex with the union of the word matchers" do
      config.with_words = "trump, musk, bolsonaro"
      expect(config.compiled_words_regex).to be_a(Regexp)
    end

    it "generates a regex that matches trump" do
      config.with_words = "trump, musk, bolsonaro"
      expect("trump".match(config.compiled_words_regex)).to be_truthy
    end

    it "generates a regex that matches musk" do
      config.with_words = "trump, musk, bolsonaro"
      expect("musk".match(config.compiled_words_regex)).to be_truthy
    end

    it "generates a regex that matches bolsonaro" do
      config.with_words = "trump, musk, bolsonaro"
      expect("bolsonaro".match(config.compiled_words_regex)).to be_truthy
    end

    it "generates a regex that matches a hashtag" do
      config.with_words = "#fml, #tbt"
      expect("i love mondays #fml".match(config.compiled_words_regex)).to be_truthy
    end

    it "generates a regex that does not match bad hashtags" do
      config.with_words = "#fml, #tbt"
      expect("i love mon#tbtdays".match(config.compiled_words_regex)).to be_falsey
    end

    it "generates a regex that does not match words in the hashtag with no hash" do
      config.with_words = "#fml, #tbt"
      expect("i love tbts".match(config.compiled_words_regex)).to be_falsey
    end

    it "generates a regex that matches hashtags begin-of-line" do
      config.with_words = "#fml, #tbt"
      expect("#fml".match(config.compiled_words_regex)).to be_truthy
    end
  end
end
