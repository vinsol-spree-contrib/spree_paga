Spree Paga [![Code Climate](https://codeclimate.com/github/vinsol/spree_paga.png)](https://codeclimate.com/github/vinsol/spree_paga) [![Build Status](https://travis-ci.org/vinsol/spree_paga.svg)](https://travis-ci.org/vinsol/spree_paga)
==========

Enable spree store to allow payment via [PAGA](https://www.mypaga.com) an online payment solution for Africa.

Installation
------------

Add `spree_paga` to your Gemfile:

```ruby
gem 'spree_paga'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_paga:install
bundle exec rake db:migrate
```


Usage
-------
This is an extension for paga payment method which used for Card payment using Paga.

It also supports partial payments(if needed)

Override Method `remaining_total` in `order_decorator.rb` to set how you would like to take amount

By default it takes order total(Full Amount).

On development mode test payment is done by default and paga notification is created(just for development Environment) else for other environments Order would only be completed on receiving success response plus success notification from Paga. 


Configuration
----------------

Setup the Payment Method
Log in as an admin and add a new Payment Method (under Configuration), using following details:

```
Name: Paga
Environment: Development (or what ever environment you prefer)
Provider: Spree::PaymentMethod::Paga
Active: Yes
```

Click **Create* , and now add your credentials in the screen that follows:


```
Private Notification Key: add your private notification key
Merchant Key: Add merchant key
Paga Script: Add script link provided from paga
```

Click Update


Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_paga/factories'
```

Contributing
------------

1. Fork the repo.
2. Clone your repo.
3. Run `bundle install`.
4. Run `bundle exec rake test_app` to create the test application in `spec/test_app`.
5. Make your changes.
6. Ensure specs pass by running `bundle exec rspec spec`.
7. Submit your pull request.


Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License