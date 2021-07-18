tweets = []
tweets << { 
  user_id: 1,
  tweet_id: 11111111, 
  tweet_date: DateTime.now,
  tweet: "content", 
  meta: { 
    screen_name: "t.user.screen_name", 
    name: "t.user.name", 
    retweet_count: "t.retweet_count", 
    favorite_count: "t.favorite_count",
    followers_count: "t.user.followers_count",
    friends_count: "t.user.friends_count",
    listed_count: "t.user.listed_count",
    statuses_count: "t.user.statuses_count"
  },
  created_at: Time.current.getlocal("+00:00"),
  updated_at: Time.current.getlocal("+00:00")
}

Tweet.insert_all(tweets, unique_by: :index_tweets_on_tweet_id_and_user_id)