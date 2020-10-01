FactoryBot.define do
  factory :user do
    sequence(:uid)  {|n| n }
    data        {}
    sequence(:screen_name)  {|n| "user#{n}" }
    secret_key { SecureRandom.uuid }
  end
  

  factory :tweet do
    sequence(:user_id) {|n| n }
    sequence(:tweet_id) {|n| n }
    tweet_date  { DateTime.now }
    created_at  { DateTime.now }
    updated_at  { DateTime.now }

    
    tweet {
      {
        "url":     "https://www.ft.com/content/a83648a9-62fe-41d2-88e4-870fb2665b60",
        "title":   "Subscribe to read | Financial TimesFinancial Times",
        "images":  [{
            "value": {
              "src": "https://www.ft.com/assets/product/dynamic-barriers/mergers-acquisitions.jpg",
              "size": [
                619,
                377
              ],
              "type": "jpeg"
            }
          }
        ],
        "videos":       [],
        "favicon":      "https://www.ft.com/__origami/service/image/v2/images/raw/ftlogo-v1%3Abrand-ft-logo-square-coloured?source=update-logos&format=svg",
        "description":  "News, analysis and comment from the Financial Times, the worldʼs leading global business publication"
      }
    }
      
    meta {
      {
        "name":            "Fake Handle",
        "screen_name":     "fakehandle",
        "retweet_count":    1,
        "favorite_count":   1
      }
    }
  end

end