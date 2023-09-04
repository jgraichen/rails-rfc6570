# Rails::RFC6570

[![Build Status](https://img.shields.io/github/actions/workflow/status/jgraichen/rails-rfc6570/test.yml?logo=github)](https://github.com/jgraichen/rails-rfc6570/actions/workflows/test.yml)

Pragmatic access to your Rails routes as RFC6570 URI templates. Tested with Rails 6.1, 7.0 and Ruby 2.7, 3.0, 3.1, 3.2.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-rfc6570', '~> 3.0'
```

## Usage

**Rails::RFC6570** gives you direct access to your Rails routes as RFC6570 URI templates using the [addressable](https://github.com/sporkmonger/addressable) gem. It further patches `Addressable::Template` with a `#as_json` and `#to_s` so that you can simply pass the template objects or even partial expanded templates to your render call, decorator or serializer.

The following examples print a JSON index resource just like `https://api.github.com`:

```ruby
class ApplicationController < ActionController::API
  def index
    render json: rfc6570_routes(ignore: %w(format), path_only: false)
  end
end
```

**Pro Tip**: Append `_url` to the route names: `rfc6570_routes.transform_keys {|k| "#{k}_url" }`.

By default, the `format` placeholder is ignored and the HTTP host will be included in the URI template.

Additionally, you can specify a list of query parameters in your controllers:

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

This gem does not support every construct possible with route matchers especially nested groups cannot be expressed in URI templates. They are expanded into separate groups. It also makes some assumptions when converting splat matchers like swallowing a multiple slashes. An error is raised when routes with OR-clauses are tried to be converted.

You can also combine **Rails::RFC6570** with [rack-link_headers](https://github.com/jgraichen/rack-link_headers) and provide hypermedia linking everywhere!

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

## Contributing

1. [Fork it](http://github.com/jgraichen/rails-routes/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Add specs
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
