from ubuntu:18.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -my wget gnupg sudo python3-dev

RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.3``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.3
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y software-properties-common postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3 git python3-pip 
# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.3`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``rescueuser`` with ``(10.4 (Ubuntu 10.4-0ubuntu0.18.04))`` as the password and then create a database `rescuekerala` owned by the ``postgres`` role.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE DATABASE rescuekerala;" &&\
    psql --command "CREATE USER rescueuser WITH SUPERUSER PASSWORD 'password';" &&\
    psql --command "GRANT ALL PRIVILEGES ON DATABASE rescuekerala TO rescueuser;"

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
#CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]

USER root

#Clone code repo
RUN git clone https://github.com/IEEEKeralaSection/rescuekerala.git

WORKDIR rescuekerala

#Copy env details
CMD ["cp",".env.example",".env"]

RUN python3 -m pip install -r requirements.txt

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
#RUN python3 manage.py migrate

#RUN python3 manage.py collectstatic

#RUN python3 manage.py runserver
