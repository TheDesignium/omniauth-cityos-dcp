# CityosDcpLogin::Omniauth::Oauth2Login
公開用の都市OSのomniauthライブラリ
Code For Japan 版のDecidimを想定しているので、他のRoRに適応されるかは未知数

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add omniauth-cityos-dcp

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install omniauth-cityos-dcp

## Usage

TODO: Write usage instructions here

管理画面にて、各種変数を追加する。
特に、
- opt_api_base_url  
  (https://[opt_api_base_url]/api/v2/users/retrieve)
- optin_url  
  (https://[optin_url]?...)
- authorization_url  
  (https://[authorization_url]/oauth2/v2.0/authorize)
については、中かっこ内を変数とし、特にスキーム部分(https://)は省略しているので注意が必要

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TheDesignium/omniauth-cityos-dcp/issues
