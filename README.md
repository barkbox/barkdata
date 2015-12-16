# Barkdata

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'barkdata', github: 'barkbox/barkdata', tag: '0.1.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barkdata

## Usage

### Installation
    $ rails g barkdata:install

### Requirements
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

### Configuration

config/initializers/barkdata.rb
```ruby
Barkdata.configure do
  Barkdata::Config.instance.project_name = 'barkbox'
  Barkdata::Config.instance.bucket = ENV['BARKDATA_BUCKET']
  Barkdata::Config.instance.enabled = ['true', '1', true, 1].include?(ENV['BARKDATA_ENABLED'])

  Barkdata.register Subscription
  Barkdata.register User do
    ignore_column 'encrypted_password'
    ignore_column 'reset_password_token'
    ignore_column 'django_encrypted_password'
    ignore_column 'authentication_token'
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkbox/barkdata.
