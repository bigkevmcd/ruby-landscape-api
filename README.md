ruby-landscape-api
==================

Ruby client library for Canonical's Landscape service.

To use this, you'll need to create an API keypair in the Landscape Web UI.

```
gem install landscape-api
```


```ruby
require 'landscape'

client = Landscape::Client.new(api_access_key: 'enter key here',
                               secret_access_key: 'enter secret here'
puts client.get_access_groups

[{'children' => '', 'name' => 'my-computers', 'parent' => 'global', 'title' => 'My Computers'}, 
 {'children' => 'my-computers', 'name' => 'global', 'parent' => '', 'title' => 'Global access'}]
```