SpreePaga
=========

Installation
------------

Add spree_paga to your Gemfile:

```ruby
gem 'spree_paga', :git => 'git://github.com/abhishekjain16/spree_paga.git'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_paga:install
bundle exec rake db:migrate
```


Usage
-------
This is an extemsion for paga payment method which used for Card payment using Paga.

It also supports partial payments(if needed)

Override Method remaining_total in order_decorator.rb to set how you would like to take amount

By default it takes order total(Full Amount).

On development mode test payment is done by default and paga notification is created(just for development Environment) else for other environments Order would only be completed on receiving success response plus success notification from Paga. 


Configuration
----------------

Setup the Payment Method
Log in as an admin and add a new Payment Method (under Configuration), using following details:

Name: Paga

Environment: Development (or what ever environment you prefer)

Provider: Spree::PaymentMethod::Paga

Active: Yes

Click **Create* , and now add your credentials in the screen that follows:


Private Notification Key: add your private notification key

Merchant Key: Add merchant key

Paga Script: Add script link provided from paga

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

Copyright (c) 2013 [name of extension creator], released under the New BSD License
