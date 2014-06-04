# Rails::RFC6570

Pragmatical access to your Rails (4.0) routes as RFC6570 URI templates.

## Installation

Add this line to your application's Gemfile:

    gem 'rails-rfc6570', '~> 0.1'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-rfc6570

## Usage

**Rails::RFC6570** gives you direct access to your Rails routes as RFC6570 URI templates using the [addressable](https://github.com/sporkmonger/addressable) gem. It further patches `Addressable::Template` with a `#as_json` and `#to_s` so that you can simply pass the template objects or even partial expanded templates to your render call, decorator or serializer.

This examples print a JSON index resource just like https://api.github.com:

```ruby
class ApplicationController < ActionController::API
  def index
    render json: rfc6570_routes(ignore: %w(format), path_only: false)
  end
end
```

**Pro Tip**: Append `_url` to the route names: `rfc6570_routes.map{|n,r| ["#{n}_url", r]}.to_h`.

By default the `format` placeholder is ignored and the HTTP host will be included in the URI template.

Additionally you can specify a list of query parameters in your controllers:

```ruby
class UserController < ApplicationController

  rfc6570_params index: [:query, :email, :active]
  def index
    # ...
  end

  def show
    # ...
  end

  # ...
end
```

Given the above and this routes

```ruby
Rails::Application.routes.draw do
  resources :users, except: [:new, :edit]
  root to: 'application#index'
end
```

the root action will return something similar to the following JSON:

```json
{
"users": "http://localhost:3000/users{?query,email,active}",
"user": "http://localhost:3000/users/{id}",
"root": "http://localhost:3000/"
}
```

You can also access your RFC6570 routes pragmatically everywhere you can access Rails' URL helpers e.g. in a decorator.

You can use this to e.g. partial expand templates for nested resources:

```ruby
module ApplicationHelpers
  include Rails.application.routes.url_helpers
end

class UserDecorator < Draper::Decorator
  def as_json(opts)
    {
      id: object.id,
      self_url: user_url(object),
      posts_url: user_posts_rfc6570.partial_expand(user_id: object.id),
    }
  end
end
```

This gem does not support every construct possible with route matchers especially nested groups cannot be expressed in URI templates. It also makes some assumptions when converting splat matchers like swallowing a multiple slashes.

You can also combine **Rails::RFC6570** with [rack-link_headers](https://jgraichen/rack-link_headers) and provide Hypermedia-linking everywhere!

```ruby
class UserController < ApplicationController
  respond_to :json

  def show
    @user = User.find
    response.link user_url(@user), rel: :self
    response.link user_posts_rfc6570.partial_expand(user_id: @user.id), rel: :posts
    response.link profile_rfc6570.expand(user_id: @user.id), rel: :profile

    respond_with @user
  end
end
```

## ToDos

* Still has *no* tests.

## Contributing

1. Fork it (http://github.com/jgraichen/rails-routes/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
