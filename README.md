# apiculture

A little toolkit for building RESTful API backends on top of Sinatra.

## Ideas

A simple API definition DSL with simple premises:
  
 * Endpoint URLs should be _visible_ in the actual code. The reason for that is with nested
   blocks you inevitably end up setting up context somewhere far away from the terminal route
   that ends up using that context.
 * Explicit allowed/required parameters (both payload/query string and body)
 * Explicit description in front of the API action definition
 * Wrap the actual work into Actions, so that the API definition is mostly routes
 
## A taste of honey

```ruby
    class Api::V2 < Sinatra::Base
      
      use Rack::Parser, :content_types => {
        'application/json'  => JSON.method(:load).to_proc
      }
      
      extend Apiculture
      
      desc 'Create a Contact'
      required_param :name, 'Name of the person', String
      param :email, 'Email address of the person', String
      param :phone, 'Phone number', String, cast: ->(v) { v.scan(/\d/).flatten.join }
      param :notes, 'Notes about this person', String
      api_method :post, '/contacts' do
        # anything allowed within Sinatra actions is allowed here, and
        # works exactly the same - but we suggest using Actions instead.
        action_result CreateContact # uses Api::V2::CreateContact
      end
      
      desc 'Fetch a Contact'
      route_param :id, 'ID of the person'
      responds_with 200, 'Contact data', {name: 'John Appleseed', id: "ac19...fefg"}
      api_method :get, '/contacts/:id' do | person_id |
        json Person.find(person_id).to_json
      end
    end
```

## Generating documentation

For the aforementioned example:

```ruby
    File.open('API.html', 'w') do |f|
      f << Api::V2.api_documentation.to_html
    end
```

or to get it in Markdown:

```ruby
    File.open('API.md', 'w') do |f|
      f << Api::V2.api_documentation.to_markdown
    end
```

## Running the tests

    $bundle exec rspec

If you want to also examine the HTML documentation that gets built during the test, set `SHOW_TEST_DOC` in env:

    $SHOW_TEST_DOC=yes bundle exec rspec

Note that this requires presence of the `open` commandline utility (should be available on both OSX and Linux).

## Contributing to apiculture
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2015 WeTransfer. See LICENSE.txt for
further details.

