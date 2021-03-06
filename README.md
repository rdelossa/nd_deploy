#ND Deploy

The purpose of this gem is to render any ruby app compatible with the ND local development.

## Installation

Add this line to your application's Gemfile:

    gem 'nd_deploy', :git => 'git@github.com:rdelossa/nd_deploy.git', :tag => '0.0.2'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nd_deploy

If you have any issues using the gem from the repo follow these directions:

https://github.com/bundler/bundler/blob/master/ISSUES.md

## Usage

<h4>Start a new app to test this gem</h4>

    $ rails new test_app

Move into the newly created app folder

    $ cd test_app

Following the installation directions above.

<h4>Run the initializer</h4>

    $ rails generate nd_deploy_initializer

Edit /config/deployment_config with the appropriate git repo and app name.  A future update will auto-populate this information.

/config/deployment_config

    set :GITHUB_SSH, "git@bitbucket.org:user_name/APP_NAME.git"
    set :APP_NAME, "APP_NAME"

<h4>Launchpad</h4>

Once your app has been set up in Launchpad you will be able to deploy it.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/nd_deploy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


