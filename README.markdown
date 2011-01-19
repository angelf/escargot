
Escargot
============

Connects any Rails model with ElasticSearch, supports near real time updates,
distributed indexing and models that integrate data from many databases.  

Requirements
============
Currently only rails 2.3 is supported. You will need ElasticSearch, the 'rubberband' gem
and (if you want to use the **optional** distributed indexing mode) Redis. 

Usage
=======

First, [download and start ElasticSearch](http://www.elasticsearch.com/docs/elasticsearch/setup/installation/) (it's really simple). With the default setup of
of ElasticSearch (listening to localhost and port 9200) no configuration of the plugin is 
necessary. 

To define an index, simply add a line to your model

    class Post < ActiveRecord::Base
      elastic_index
    end

To create the index, execute the rake task that rebuilds all indexes:

    rake escargot:index

Or restrict it to just one model
    
    rake "escargot:index[Post]"
    
And you are ready to search:

    Post.search "dreams OR nightmares" 

Near Real Time support
=======

The default behavior is that every time you save or delete a record in an indexed model
the index will be updated to reflect the changes. You can disable this by 

    class Post < ActiveRecord::Base
      elastic_index :updates => false
    end

Please notice that when updates are enabled there may be a slight delay for the changes to appear
in search results (with the default elasticsearch settings, this delay is just 1 second). If 
you absolutely need to ensure that the change is made public before returning control to the user,
 the `:immediate_with_refresh` option provides this assurance.

    class Post < ActiveRecord::Base
      elastic_index :updates => :immediate_with_refresh
    end

Enabling `:immediate_with_refresh` is not recommended. A better option is to simply call `Post.refresh_index`
when you really need the guarantee. 

Choosing the indexed fields
=======

This plugin doesn't provide a DSL to define what fields you want to be indexed. Instead of that
it exposes the fact that in ElasticSearch every document is just a JSON string. 

If you define a `indexed_json_document` method in your model this will be used as the JSON 
representation of the document, otherwise `to_json` will be called instead.

Luckily, ActiveRecord has excellent support for JSON serialization, so it's really easy
to include associations or custom methods.

     class Post < ActiveRecord::Base
      elastic_index :updates => false
      belongs_to :category
  
      def indexed_json_document 
        to_json(:include => :category, :methods => :slug)
      end
  
      def slug
        title.downcase.gsub(" ", "-")
      end
     end

See [ActiveRecord's JSON serialization documentation](http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html)

Search features
=======

Basic Searching
----------------

Calling `Model.search` obtains from ElasticSearch the ids of the results matching 
your query and then queries your database to get the full ActiveRecord objects.

    results = Post.search "dreams OR nightmares" 
    results.each {|r| puts r.title}

The query is parsed using lucene's [QueryParser syntax](http://lucene.apache.org/java/2_4_0/queryparsersyntax.html).
You can use boolean operators, restrict your search to a field, etc.

    results = Post.search "prologue:dream OR epilogue:nightmare" 

You can also guide the interpretation of the query, with the options `:default_operator` and `:df` (default_field). These two are equivalent:

    results = Post.search "title:(dreams AND nightmares)"
    results = Post.search "dreams nightmares" , :default_operator => 'AND', :df => 'title'

Sorting by attributes
--------

The default order is based on the relevancy of the terms in the document. You can also
sort by any other field's value.

    Post.search "dreams", :order => :updated_at
    Post.search "dreams", :order => 'updated_at:desc'
    Post.search "dreams", :order => ['popularity:desc', 'updated_at:desc']

Sorting by an arbitrary script is possible using the Query DSL. 
  
Pagination
----------

`search` returns a WillPaginate collection and accepts the customary *:per\_page*, and *:page* parameters.

    # controller
    @posts = Post.search("dreams", :page => params[:page], :per_page => 30)
  
    # in the view:
    will_paginate @posts
  
  
Query DSL
----------------
Instead of a string, you can pass a query in ElasticSearch's [Query DSL](http://www.elasticsearch.com/docs/elasticsearch/rest_api/query_dsl/)
giving you access to the full range of search features. 

    Bird.search(:match_all => true}  
      
    Bird.search(:fuzzy => {:name => 'oriale'})

    Bird.search(:custom_score => {:query => {:match_all => true}, :script => "random()"})
    
    Bird.search(:dis_max => {
      :tie_breaker => 0.7,
      :boost => 1.2,
      :queries => [:term => {:name => 'oriole'}, :term => {:content => 'oriole'}]
    })

    Bird.search(:more_like_this => {
      :like_text => "The orioles are a family of Old World passerine birds"
    })

 
    Bird.search(
      :filtered => {
        :query => {
          :term => {:name => 'oriole'}
        },
        :filter => {
          :term => {:suborder => 'Passeri'}
        }
      }
    )
  
Facets
----------------
  
Term facets returning the most popular terms for a field and partial results counts are 
available through the `facets` class method.

    Post.facets :author_id
    Post.facets :author_id, :size => 100
    
    # restrict the facets to posts that contain 'dream'
    Post.facets :author_id, :query => "dream"
    Post.facets [:author_id, :category], :query => "dream"     

This returns a Hash of the form:

    {
     :author_id => {
       "1" => 3,
       "25" => 2
      }, 
      :category_id => {
         12 => 4,
         42 => 7,
         47 => 2
       }
    }

<!-- You can also combine the standard search results with the facets counts in a single request. 

    results = Post.search_with_facets [:author, :category], :query => "dream"
    results.each{|post| puts post.title}
    results.facets -->

You should be aware that this only a very simple subset of the facets feature of ElasticSearch.
The full feature set (histograms, statistical facets, geo distance facets, etc.) is available
through the Query DSL. 

  
Search counts
----------

Use `search_count` to count the number of matches without getting the results.  

    Post.search_count("dream OR nightmare")
  
  
Index Creation and Type Mapping Options
=======

Index creation options
-----------------------

Any value passed in the :index\_options argument will be sent to ElasticSearch as an index
creation option.

For example, if you want to increase the number of shards for this index:
 
    class Post < ActiveRecord::Base
      elastic_index :index_options => {:number_of_shards => 10}
    end

If you want the search to be insensitive to accents and other diacritics:

    class Post < ActiveRecord::Base
      elastic_index :index_options => {
          "analysis.analyzer.default.tokenizer" => 'standard',
          "analysis.analyzer.default.filter" => ["standard", "lowercase", "stop", "asciifolding"]
      }
    end

The full list of available options for index creation is documented at
[http://www.elasticsearch.com/docs/elasticsearch/index_modules/](http://www.elasticsearch.com/docs/elasticsearch/index_modules/)

Mapping options
----------------

Mapping is the process of defining how a JSON document should be mapped to the Search Engine,
including its searchable characteristics.

The default (dynamic) mapping provides sane defaults, but defining your own mapping enables
powerful features such as boosting a field, using a different analyzer for one field, 
enabling term vectors, etc.

Some examples:

    class Post < ActiveRecord::Base
      elastic_index :mapping_options => {
        :properties => {
          :category => {:type => :string, :index => :not_analyzed}, 
          :title => {:type => :string, :index => :analyzed, :term_vector => true, :boost => 10.0},
          :location => {:type => :geo_point}
        }
      }
    end


See the [ElasticSearch Documentation](http://www.elasticsearch.com/docs/elasticsearch/mapping/) for mappings.

Distributed indexing
=======
You will need distributed indexing when there is a large amount of data to be indexed. In this 
indexing mode the task of creating an index is divided between a pool of workers that can be 
as large as  you need. Since ElasticSearch itself provides linear indexing scalability by adding 
nodes to the cluster, this means that you should, in principle, be able to make your indexing
time arbitrarily short.  

Currently, the only work queue supported is [Resque](http://github.com/defunkt/resque). To enable distributed indexing you
should first install Redis and set-up Resque. 

If you're on OS X and use homebrew, installing redis can be done with:

    brew install redis
    redis-server /usr/local/etc/redis.conf

Install the resque gem:

    $ gem install resque
  
Include it on your application:

    require 'resque'

Add this to your Rakefile:

    require 'resque/tasks'
    namespace :resque do
      task :setup => :environment
    end
  
And use the resque:work rake task to start a worker:

     $ QUEUE=es_admin,es_nrt,es_batch rake resque:work

Once you have set-up Resque and started a number of workers, you can easily create an index for you model using the distributed model:

    rake "elasticsearch:distributed_index[Post]"

or if you want to re-create all your indexes

    rake elasticsearch:distributed_index

Be aware that due the distributed nature of indexing the new index may be deployed when some workers are still performing their last
indexing job. 

Setting up a resque work queue also allows you to use the *:update => :enqueue* option

    class Post < ActiveRecord::Base
      elastic_index :update => :enqueue
    end

With this setting when a document is updated or deleted the task of updating the index is 
added to the work queue and will be performed asynchronously by a remote agent. 
 
Index versions
=======
In *escargot* indexes are versioned: when you create an index for the
model Post the actual index created in ElasticSearch will be named something like
'posts\_production\_1287849616.57665' with an alias 'posts\_production' pointing to it. The second time 
you run the "escargot:index" tasks a new index version will be created and the 
alias will be updated only when the new index is ready. 

This is useful because it makes the deployment of a new index version atomic. 

When a document is saved and index updates are enabled, both the current index version
and any version that's in progress will be updated. This ensures that when the new
index is published it will include the change. 

Contributing
================
Fork on GitHub, create a test & send a pull request. 

Bugs
================
Use the [Issue Tracker](http://github.com/angelf/escargot/issues)

 
Aknowledgements
================
* Some parts of the API plagiarize the excellent Thinking Sphinx plugin, and more will do so in the future.
* This plugin depends on rubberband for communication with ElasticSearch.
* Elastic Search rules!

Future Plans
======

Search features:
* Field conditions and term filters
* Searching multiple models
* Single-table inheritance support
* (optionally) use the _source field from ES and avoid querying the database 

Indexing features:
* Distributing the task of listing document ids
* Index partioning
* Support for non-ActiveRecord models
* Adding other queue backends

Copyright (c) 2010 Angel Faus & vLex.com, released under the MIT license
