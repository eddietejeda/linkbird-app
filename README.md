## What is LinkBird?

LinkBird is a toy app to play with different technologies. It allows you to interesting articles without having to go to Twitter.

- [LinkBird Infrastructure - Terraform](https://github.com/eddietejeda/linkbird-infrastructure/)
- Backend written in Ruby, Sinatra,
- Front-end will ES66 Vanilla JS compiled with Webpack


## How does LinkBird work?

LinkBird connects to your account and looks for links shared by the people that you follow. LinkBird then shows a preview of the article in a minimalist layout.  

When you first create an account, you will only see a couple links, but after a couple of minutes, LinkBird and Twitter will stay in sync.  If you're on a mobile device, you also can refresh your links by pulling down on the LinkBird timeline.

Over time, we'll be adding features that will make it easy for you to slice and dice your links in creative ways.  If you have any feedback or suggestions, please contact suggestions@linkbird.app.

<img src="https://raw.githubusercontent.com/eddietejeda/linkbird-application/master/public/images/phone-view.png?token=AAFDSJASYLORNG42XWNLZLLAU4EO2" width=200px>



# Download Source

```
    git clone git@github.com:eddietejeda/linkbird-application.git
    cd linkbird-application/
```


# Install Locally

```
    bundle install;
    bundle exec rake db:create;
    bundle exec rake db:seed;    # Optional
    npm install
    npm run build
```


# Docker Installation

```
    docker compose up
```




# Deploy to AWS

```
    git clone git@github.com:eddietejeda/linkbird-application.git
    cd linkbird-application/


```


# Deploy to Heroku

```
    heroku create linkbird-test
    heroku git:remote -a linkbird-test
    git push heroku master
```
