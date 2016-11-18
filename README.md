# Centos RethinkDb

The RethinkDb datastore is configured here to run inside a [Docker](https://www.docker.com) container, managed by [supervisord](https://supervisord.org/) encapsulating all the dependencies it needs and configuring it with the appropriate parameters for communicating with the web applications that use it.

# Installation

Docker and Docker-Compose are required to run this application, which are packaged together for Mac and Windows users into [Docker Toolbox](https://www.docker.com/products/docker-toolbox), for Linux users, follow the instructions for installing  the [Docker Engine](https://docs.docker.com/engine/installation/) and [Docker Compose](https://docs.docker.com/compose/install/).

# Running the Application

After installing the Docker dependencies, navigate to __centosrethinkdbsupervisor__ folder and execute the following from the command line:

```
make docker
```

That command will build an image (using the `Dockerfile` "recipe" in this project folder) from which containers can be created.

Next, we'll create the docker container that holds the RethinkDb instance using the `docker-compose` command (__note__: Docker Compose is in many ways just a shortcut for the operations we'd otherwise be running from the command line in a very, very long statement):

```
docker-compose up
```

Although this Docker Compose by default execute an interactive container (which logs activity to stdout, in this case) and allows you to stop the container with the standard `CTRL`+`C` kill, we can always run it silently (non-interactive) in the background by passing the `-d` argument:

```
docker-compose up -d
```

If you successfully started up your container non-interactively, you should see it list when you execute the following command:

```
docker ps
```

That command (without arguments passed to it) shows only the running containers (also lists the image they were built from), and it should show your _centosrethinkdbsupervisor_ image and container.

__Note__: you will need to stop the container the standard way if you chose to run it non-interactively, by executing the following command:

```
docker stop centosrethinkdbsupervisor
```

Additionally, this rethinkdb container is configured to bind to any IP address that attempts to communicate through the exposed ports. Although this is standard for development purposes, it should be necessary to specify a hostname or ip address that is "whitelisted". You can do this when you run the container, and to do so you need to create an entry in the `docker-compose.yml` file for an environment variable (the `Dockerfile` that builds the _centosrethinkdbsupervisor_ image sets default values for certain environment variables used by `supervisord` unless you override them with user-supplied values). Add the following line to have the container bind only to an IP address of 172.17.0.2

```
  environment:
    BIND_IP: '172.17.0.2'
```

That value will override the default value for that environment variable (which is "all").

__note__: you can always find the IP address for a running docker container by executing the command `docker inspect <my container name> | grep IPADDRESS`

# About RethinkDb
Its syntax is easy for developers to grasp, using a fluent API where each operation chains to the next, and is particularly well-suited to JavaScript developers. The syntax is also intuitive from a back-end developer or DBA's perspective as the means of constructing a query also lays out the execution plan, leaving less abstraction between the way to write the query and the way the database engine is grabbing the data.

Being reactive, RethinkDb is an ideal pairing with a [Meteor](https://www.meteor.com/), [Socket.IO](http://socket.io/), or [Meatier](https://github.com/mattkrick/meatier) application. It implements a publish/subscribe pattern where server and subscribers configure an exchange and the client subscribes to "topics" and monitors the queue for changes. It also integrates easily with [RabbitMQ](https://rethinkdb.com/docs/rabbitmq/javascript/) and [Elasticsearch](https://rethinkdb.com/docs/elasticsearch/) with other integrations available through the community.

RethinkDb is a document database and more comparable to several NoSQL database solutions in the market today (such as Mongo, CouchDB, Redis, etc.), yet it offers SQL-like features, such as joins and treats its entities as _tables_ (rather than documents) which hold _rows_ of JSON documents. Additionally, it offers more native data types than are available in the other NoSQL stores (binary data, `date`, `time`, `null` and geospatial queries), it allows using streams - which provide you a cursor that points to the matching result set, allowing you to work with large data sets (lazy-loading).

RethinkDb - like Redis (and unlike Mongo) - horizontally scales very well and allows for sharding. Setup and removal of multiple instances of RethinkDb is easy to do and you can even execute table joins across instances. The same fluent API available for writing queries can also be used to spin up multiple instances and configure shards.

## Interacting with RethinkDb's Web Interface

Once your instance of __centosrethinkdbsupervisor__ is running, it can be accessed by a web application you write that communicates with it through the driver ports, however a web interface is also available for administrative access. Much like any standard Database IDE, you can run queries, modify databases & tables, or configure deployment settings. It is suggested at the very least to make yourself familiar with the Data Explorer tool.

Once your rethinkdb instance is running, navigate to [localhost:8080](http://localhost:8080) and click on the _Data Explorer_ option from header menu bar.

You can execute commands (with full intellisense too) inside the text box. Either hit the __Run__ button or type `SHIFT`+`ENTER`.


### Basic tour of ReQL commands

Create a table:

```
r.db('test').tableCreate('users')
```

Insert a row:
```
r.db('test').table('users').insert({
  name: 'David',
  surname: 'Nunez',
  email: 'person@email.com',
  address: {
    street: '700 E. Main Rd.',
    city: 'Phoenix',
    state: 'AZ',
    zipcode: '85004'
  },
  interests: [
    'programming',
    'reading',
    'burritos'
  ]
})
```

View a table's rows
```
r.db('test').table('users')
```

Modify the returned results to only select columns/fields:
```
r.db('test').table('users').pluck('name', 'email')
```

Or return a nested object (in JavaScript this double-parenthesis syntax is just a function returning a function):
```
r.db('test').table('users')('address')
```

Filter results based on a matched value:
```
r.db('test').table('users').filter(r.row('name').eq('David'))
```

Or matching on a nested object's details:
```
r.db('test').table('users')('address').filter(r.row('city').eq('Phoenix'))
```

More complicated matching (with regular expressions):
```
r.db('test').table('users').filter({
    address: {
      city: 'Phoenix'
    }
  })
  .filter(doc => doc('email').match('(@email.com)$'))
```

Create an index based on a matching field called `name` (you can also do this from the admin panel):

```
r.db('test').table('users').indexCreate('name')
```

Create a compound (multi-field) index:

```
r.db('test').table('users').indexCreate('name', [r.row('name'), r.row('surname')])
```

Run a query, using an index (for optimal performance):

```
r.db('test').table('users').getAll('Alex', {index: 'name'})

// OR

r.db("test").table('users').getAll(['Alex', 'Smith'], {index: 'name_and_surname'})
```

Apply paging and sorting (`.skip()`, `.limit()` and `orderBy()`):

```
// This would return results in descending order by name, but take page 2 of the results
r.db('test').table('users').orderBy(r.desc('name')).skip(10).limit(10)

// Varied slightly, and with indexing . . .
r.db('test').table('users').orderBy({index: r.asc('name_and_surname')}).skip(10).limit(10)
```

You can also apply grouping, and take advantage of a cool feature in rethinkdb, called "ungrouping" to perform operations after a grouping:

```
// The "reduction" is the aggregate column (count, average, max, etc.)
r.db('test').table('users').group('surname').count().ungroup().orderBy(r.desc('reduction'))
```

Clear a record:
```
r.db('test').table('users').filter(r.row('name').eq('David')).delete()
```

Or delete all rows from the table:

```
r.db('test').table('users').delete()
```

And to drop the table:

```
r.db('test').tableDrop('users')
```

## Additional Resources

* [ReQL](https://rethinkdb.com/docs/introduction-to-reql/)
* [Getting Started with RethinkDb](https://www.packtpub.com/big-data-and-business-intelligence/getting-started-rethinkdb)
