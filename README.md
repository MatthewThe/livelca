# LiveLCA rails app

https://livelca.com

This README documents the necessary steps to get the application up and running.

## Ruby version

ruby 3.1.7

## System dependencies

## Configuration

Editing passwords:

```
EDITOR="nano" rails credentials:edit
```

## Database creation

```
setup_vm.sh
```

## Database initialization

Change password in the neo4j browser

```
unpack_graph_db.sh
```

## Migration

```
rake neo4j:migrate
```

and restart the server

## Deployment instructions server

1. Create a zip file from the neo4j database you want to use as a base:
   ```
   pack_graph_db.sh
   ```

2. Copy the `.env` and `docker-compose.yml` files to the server
   ```
   scp {.env,docker-compose.yml} <remote>:~/
   ```

3. SSH into the server and execute the setup bash script. This installs git, docker and docker-compose and sets up the folder structure for neo4j:
   ```
   setup_vm.sh
   ```
   
4. Transfer the zipped neo4j database to the server and unzip in the neo4j folder:
   ```
   scp_dev_db.sh
   unpack_graph_db.sh
   ```

5. Start up the docker
   ```
   sudo docker-compose up --detach
   ```

6. Check the logs of docker-compose to verify everything started correctly
   ```
   docker-compose logs
   ```

7. Configure NGINX and certbot to provide https support: https://github.com/MatthewThe/nginx-certbot

## Update instructions server

1. Update the docker
```
build.sh
```

2. Push the docker to DockerHub
```
docker push matthewthe/livelca:latest
```

3. SSH into the server and deploy the new docker
```
docker pull matthewthe/livelca
docker-compose up -d --no-deps --build web
```

4. If there was a change to the database (e.g. a migration after adding a new model), find the docker container id for matthewthe/livelca and run
```
docker exec -it <livelca_docker_container_id> /bin/bash
$ bin/rake db:migrate RAILS_ENV=production
```
you might have to redeploy 
```
docker-compose up -d --no-deps --force-recreate --build web
```

## Deployment instructions local

```
rake neo4j:start
rails server -u webrick
```

or to make it accessible from other computers in the network

```
rake neo4j:start
rails server -b 0.0.0.0 -u webrick
```

then use ip addr show to find your local ip address

Setting up a neo4j server in the Google Cloud Platform:
```
gcloud compute instances create neo4j-livelca --image neo4j-community-1-3-5-1-apoc --tags neo4j --image-project launcher-public --machine-type f1-micro
```


## Debugging

Check if connection to Neo4j is working:

```
rails console

driver = ActiveGraph::Base.driver

# open a session
session = driver.session

# run a simple query
result = session.run("RETURN 1 AS number")

# check output
result.each { |record| puts record["number"] }

# close the session
session.close
```

## Useful Cypher queries

### Updating study weights for a resource

```
MATCH (n:Resource)-[:IS_RESOURCE]->(s:Source) WHERE n.name CONTAINS "<XXX>" SET s.weight = 5
```

### Deleting all sources for a resource

```
MATCH (n:Resource)-[:IS_RESOURCE]->(s:Source) WHERE n.name CONTAINS "<XXX>" DETACH DELETE s
```

### Find orphaned products

```
MATCH (p:Product) WHERE NOT (p)-[:IS_SUBCATEGORY_OF]->(:Product) RETURN p
```

## Setup Matomo

Matomo tracks visitors in a GDPR compliant way, without the need to ask for tracking permission.

It's setup via ssl on `matomo.livelca.com` on the nginx server (redirected to the 8080 port over the 443 ssl port).

Add the following lines to the General section in `/var/www/html/config/config.ini.php`.

The `proxy_*` lines ensure that the right IP address is shown in the Matomo dashboard.

```
[General]
trusted_hosts[] = "matomo.livelca.com"
assume_secure_protocol=1
proxy_client_headers[] = HTTP_X_FORWARDED_FOR
proxy_host_headers[] = HTTP_X_FORWARDED_HOST
```


## Upgrading ruby and rails versions

Compatibility table: https://www.fastruby.io/blog/ruby/rails/versions/compatibility-table.html

### Installing new rubygems after problems with SSL certificate

```
wget -P /home/matthewt/.rbenv/versions/2.7.0/lib/ruby/2.7.0/rubygems/ssl_certs/rubygems.org/ https://raw.githubusercontent.com/rubygems/rubygems/master/lib/rubygems/ssl_certs/rubygems.org/GlobalSignRootCA_R3.pem
gem update --system
```

### Upgrading ruby version

```
git -C ~/.rbenv/plugins/ruby-build pull
rbenv install 3.1.7
rbenv global 3.1.7

gem install rails
rbenv rehash
bundle install
```

```
sudo apt install openjdk-8-jre-headless
sudo update-alternatives --config java # select Java 8
```