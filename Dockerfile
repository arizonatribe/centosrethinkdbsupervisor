FROM arizonatribe/centos
MAINTAINER David Nunez <arizonatribe@gmail.com>

ENV APP_NAME centosrethinkdb

# Add RethinkDb repo and install it
RUN wget http://download.rethinkdb.com/centos/7/`uname -m`/rethinkdb.repo \
          -O /etc/yum.repos.d/rethinkdb.repo
RUN yum install rethinkdb -y

# Install the RethinkDb CLI through python PIP
RUN pip install rethinkdb

# Create the application and logging directories and set ownership to the rethinkdb user/group
RUN mkdir -p /var/{log/rethinkdb,lib/rethinkdb,run/rethinkdb}
RUN chown -R rethinkdb:rethinkdb /var/log/rethinkdb /var/lib/rethinkdb /var/run/rethinkdb

# Directory to run application from
WORKDIR /var/lib/rethinkdb

# Ports exposed for database operation and driver ports, as well as web admin access
# Since we may want to spin up a cluster of multiple rethinkdb instances (and because
# there is currently no way to have EXPOSE read an environment variable passed in
# dynamically) we can expose a range of ports and use the rethinkdb CLI's --port-offset
# option (in tandem with the `docker run -p ` option) to map non-overlapping ports unique
# to each container built from this one image
EXPOSE 28015-28025
EXPOSE 29015-29025
EXPOSE 8080-8090

# Exposing this container as an entrypoint allows us to append onto it from
# docker-compose or `docker run` just as if we were executing rethinkdb CLI directly
ENTRYPOINT [ "/usr/bin/rethinkdb" ]
