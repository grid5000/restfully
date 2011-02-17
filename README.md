# restfully

An attempt at dynamically providing wrappers on top of RESTful APIs that follow the principle of Hyperlinks As The Engine Of Application State (HATEOAS). 
It does not require to use specific (and often complex) server-side libraries, but a few constraints and conventions must be followed:

1. Return sensible HTTP status codes;
2. Make use of GET, POST, PUT, DELETE HTTP methods;
3. Return a Location HTTP header in 201 or 202 responses;
4. Return a <tt>links</tt> property in all responses to a GET request, that contains a list of link objects:

              {
                "property": "value",
                "links": [
                  {"rel": "self", "href": "uri/to/resource", "type": "application/vnd.whatever+json;level=1,application/json"},
                  {"rel": "parent", "href": "uri/to/parent/resource", "type": "application/json"} 
                  {"rel": "collection", "href": "uri/to/collection", "title": "my_collection", "type": "application/json"}, 
                  {"rel": "member", "href": "uri/to/member", "title": "member_title", "type": "application/json"}
                ]
              }
   
   * Adding a <tt>parent</tt> link automatically creates a <tt>#parent</tt> method on the current resource. 
   * Adding a <tt>collection</tt> link automatically creates a <tt>#my_collection</tt> method that will fetch the Collection when called. 
   * Adding a <tt>member</tt> link automatically creates a <tt>#member_title</tt> method that will fetch the Resource when called.

5. Advertise allowed HTTP methods in the response to GET requests by returning a <tt>Allow</tt> HTTP header containing a comma-separated list of the HTTP methods that can be used on the resource. This will allow the automatic generation of methods to interact with the resource. e.g.: advertising a <tt>POST</tt> method (<tt>Allow: GET, POST</tt>) will result in the creation of a <tt>submit</tt> method on the resource.

## Installation

    $ gem install restfully

## Usage

### Command line

    $ export RUBYOPT="-rubygems"
    $ restfully base_uri [-u username] [-p password]
  
e.g., for the Grid5000 API:

    $ restfully https://api.grid5000.fr/sid/grid5000 -u username -p password

If the connection was successful, you should get a prompt. You may enter:

    irb(main):001:0> pp root

to get back a pretty-printed output of the root resource:

    #<Restfully::Resource:0x91f08c
      @uri=#<URI::HTTP:0x123e30c URL:http://api.local/sid/grid5000>
      LINKS
        @environments=#<Restfully::Collection:0x917666>,
        @sites=#<Restfully::Collection:0x9170d0>,
        @version=#<Restfully::Resource:0x91852a>,
        @versions=#<Restfully::Collection:0x917e68>
      PROPERTIES
        "uid"=>"grid5000",
        "type"=>"grid",
        "version"=>"4fe96b25d2cbfee16abe5a4fb999c82dbafc2ee8">

You can see the `LINKS` and `PROPERTIES` headers that respectively indicate what links you can follow from there (by calling `root.link_name`) and what properties are available (by calling `root[property_name]`).

Let's say you want to access the collection of `sites`, you would enter:

    irb(main):002:0> pp root.sites

and get back:

    #<Restfully::Collection:0x9170d0
      @uri=#<URI::HTTP:0x122e128 URL:http://api.local/sid/grid5000/sites>
      LINKS
        @version=#<Restfully::Resource:0x8f553e>,
        @versions=#<Restfully::Collection:0x8f52be>
      PROPERTIES
        "total"=>9,
        "version"=>"4fe96b25d2cbfee16abe5a4fb999c82dbafc2ee8",
        "offset"=>0
      ITEMS (0..9)/9
        #<Restfully::Resource:0x9058bc uid="bordeaux">,
        #<Restfully::Resource:0x903d0a uid="grenoble">,
        #<Restfully::Resource:0x901cc6 uid="lille">,
        #<Restfully::Resource:0x8fff0c uid="lyon">,
        #<Restfully::Resource:0x8fe288 uid="nancy">,
        #<Restfully::Resource:0x8fc4a6 uid="orsay">,
        #<Restfully::Resource:0x8fa782 uid="rennes">,
        #<Restfully::Resource:0x8f8bb2 uid="sophia">,
        #<Restfully::Resource:0x8f6c9a uid="toulouse">>

A Restfully::Collection is a special kind of Resource, which includes the Enumerable module, which means you can call all of its methods on the `Restfully::Collection` object. 
For example:

    irb(main):003:0> pp root.sites.find{|s| s['uid'] == 'rennes'}
    #<Restfully::Resource:0x8fa782
      @uri=#<URI::HTTP:0x11f4e64 URL:http://api.local/sid/grid5000/sites/rennes>
      LINKS
        @environments=#<Restfully::Collection:0x8f9ab2>,
        @parent=#<Restfully::Resource:0x8f981e>,
        @deployments=#<Restfully::Collection:0x8f935a>,
        @clusters=#<Restfully::Collection:0x8f9d46>,
        @version=#<Restfully::Resource:0x8fa354>,
        @versions=#<Restfully::Collection:0x8fa0b6>,
        @status=#<Restfully::Collection:0x8f95ee>
      PROPERTIES
        "name"=>"Rennes",
        "latitude"=>48.1,
        "location"=>"Rennes, France",
        "security_contact"=>"rennes-staff@lists.grid5000.fr",
        "uid"=>"rennes",
        "type"=>"site",
        "user_support_contact"=>"rennes-staff@lists.grid5000.fr",
        "version"=>"4fe96b25d2cbfee16abe5a4fb999c82dbafc2ee8",
        "description"=>"",
        "longitude"=>-1.6667,
        "compilation_server"=>false,
        "email_contact"=>"rennes-staff@lists.grid5000.fr",
        "web"=>"http://www.irisa.fr",
        "sys_admin_contact"=>"rennes-staff@lists.grid5000.fr">

or:

    irb(main):006:0> root.sites.map{|s| s['uid']}.grep(/re/)
    => ["grenoble", "rennes"]

A shortcut is available to find a specific entry in a collection, by entering the searched `uid` as a Symbol:

    irb(main):007:0> root.sites[:rennes]
    # will find the item whose uid is "rennes"

For ease of use and better security, you may prefer to use a configuration file to avoid re-entering the options every time you use the client:

    $ echo '
    base_uri: https://api.grid5000.fr/sid/grid5000
    username: MYLOGIN
    password: MYPASSWORD
    ' > ~/.restfully/api.grid5000.fr.yml && chmod 600 ~/.restfully/api.grid5000.fr.yml

And then:

    $ restfully -c ~/.restfully/api.grid5000.fr.yml

### As a library
See the `examples` directory for examples.

## Discovering the API capabilities
A `Restfully::Resource` (and by extension its child `Restfully::Collection`) has the following methods available for introspection:

* `links` will return a hash whose keys are the name of the methods that can be called to navigate between resources;
* `http_methods` will return an array containing the list of the HTTP methods that are allowed on the resource;

## Development

### Testing

* `rake spec`; or
* run `autotest` in the project directory.

### Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull).
* Send me a pull request. 

## Copyright

Copyright (c) 2009 Cyril Rohr, INRIA Rennes - Bretagne Atlantique. See LICENSE for details.
