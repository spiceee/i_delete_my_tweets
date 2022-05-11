# I Delete My Tweets

<img width="800" alt="Screen Shot 2022-05-11 at 19 04 53" src="https://user-images.githubusercontent.com/12278/167955371-a24ec8e6-bd9a-4014-bc25-9fb9e3cb21ce.png">


A **CLI** (as in Command Line Interface) to delete your tweets based on faves, RTs, and time.

There are some services out there with a friendly web interface, but this is not one of them.
You must know the basics of working with a UNIX terminal and configuring a Twitter API app, as this
will only work if you have a Twitter Developer account.

Due to the irrevocable nature of tweet deletion, all delete commands are `dry-run` true, meaning
you must call all of them with a `--dry-run=false` flag if you want them to really do something.

Called with `--dry-run=false`, there is no way to revoke tweet deletion. They are just gone, disappeared into the ether (or the stashed in the Twitter-owned secret place you have no access to without a mandate since nothing gets _really_ deleted from the web these days, folks).

This tool won't delete all of your tweets in one fell swoop; it is more of a way to delete your old tweets from time to time. The [Twitter API rate limits](https://developer.twitter.com/en/docs/twitter-api/rate-limits) are relatively complicated, and I don't even wanna go there, but if you do intend on deleting all of your tweets, you can do it with this CLI and some perseverance. I did delete more than 100k of mine by using this script every day for a couple of weeks. The more tweets you delete, the fewer of them you have, and with time the rate limits won't be that much of a problem.

I Delete My Tweets (IDMT) can delete your tweets by fetching them via API using an APP you will have to set up yourself. Still, it can also delete tweets from an CSV (comma-separated file) that you can generate from the archive you can request from twitter.com by going to Settings and privacy > Your Account > Download an archive of your data. It is out of the scope of this CLI to generate the CSV (at the moment) but [there are scripts out there](https://gist.github.com/jessefogarty/b0f2d4ea6bdd770e5e9e94d54154c751) that can do this for you.

> TIP: You can find an example of the CSV header in the project's root folder.

These are the keys/values that make the script work. They are read from and written to
a `.i_delete_my_tweets` env file in your user directory (~/). You can fill
the values yourself or work with the <config store> commands (see Usage) to do that interactively.

| KEY                 | VALUE                       | DESCRIPTION                              |
| ------------------- | --------------------------- | ---------------------------------------- |
| CONSUMER_KEY        | String                      | Your Twitter App key                     |
| CONSUMER_SECRET     | String                      | Your Twitter App secret                  |
| ACCESS_TOKEN        | String                      | Account access token                     |
| ACCESS_TOKEN_SECRET | String                      | Access token secret                      |
| OLDER_THAN          | "2022-04-28 21:20:47 -0300" | A timestamp                              |
| PATH_TO_CSV         | './tweets.csv'              | A path to a CSV file                     |
| FAVE_THRESHOLD      | 3                           | Minimum number of faves to skip deletion |
| RT_THRESHOLD        | 5                           | Minimum number of RTs to skip deletion   |
| SCREEN_NAME         | jack                        | The account screen_name                  |

Since you have to call commands with `--dry-run=false` for them to really take action, just play around with the skip rules before using `--dry-run=false` and see what works for you.

## Install

```sh
$ gem install i_delete_my_tweets
```

IDMT is compatible with ruby-2.6.5 up.

## Usage

```sh
$ i_delete_my_tweets -h
```

Will print all commands and options.

```sh
$ i_delete_my_tweets -v
```

Gives you the version.

### Commands

```sh
$ i_delete_my_tweets config store key value
```

### Set-up

- [Create a Twitter Developer Account](https://developer.twitter.com/en/apply) if you don't already have one.

  You have to wait for the account to be reviewed and approved.

- [Create a Twitter App](https://developer.twitter.com/en/apps/create) with read and write permission
- Take note of the app's `CONSUMER_KEY` and `CONSUMER_SECRET`

#### Config

```sh
$ i_delete_my_tweets config store CONSUMER_KEY 9183921819809283910f
$ i_delete_my_tweets config store CONSUMER_SECRET 0293090239-2039209302-238392839
$ i_delete_my_tweets config store RT_THRESHOLD 2
$ i_delete_my_tweets config store FAVE_THRESHOLD 2
$ i_delete_my_tweets config store OLDER_THAN 2021-11-02
$ i_delete_my_tweets config store SCREEN_NAME mytwitterhandle
```

IDMT can generate an `ACCESS_TOKEN` and `ACCESS_TOKEN_SECRET` for you using a PIN provided
that you do have a Twitter App setup and `CONSUMER_KEY` and `CONSUMER_SECRET`.

You can bypass most of the configuration by doing a

```sh
$ i_delete_my_tweets config authorize_with_pin <consumer-key> <consumer-value>
```

It will generate a URL that will take you to Twitter and issue a PIN. Then IDMT will
configure `ACCESS_TOKEN`, `ACCESS_TOKEN_SECRET`, and `SCREEN_NAME` for you.

At any point, you can check if all keys/values are good to go with

```sh
$ i_delete_my_tweets config check
```

#### Delete

```sh
$ i_delete_my_tweets delete start
```

Will start traversing the API for your tweets and applying the `OLDER_THAN`, `FAVE_THRESHOLD`, and `RT_THRESHOLD` rules (they are applied in this order). The rules are NOT combined. If the first one matches the data in the tweet, the tweet is skipped, next one.

Pass in `--dry-run=false` if you REALLY want to delete them otherwise this command will just output the tweets it would delete but doesn't because
the default flag for delete commands is `--dry-run=true`.

```sh
$ i_delete_my_tweets delete from_csv
```

Will use the tweets from the CSV file and not fetch the API for them. This is a nice option if you want to avoid some of the API rate limits and will be a little faster since it will not do the initial tweet-fetching over HTTP.
