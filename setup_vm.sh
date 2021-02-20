sudo apt-get update
sudo apt-get install git docker.io zip unzip

sudo usermod -aG docker ${USER}

sudo mkdir -p /var/lib/neo4j/data
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo chown -R 101:101 /var/lib/neo4j/data

sudo mkdir -p /var/lib/neo4j/plugins
sudo curl -L https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.5.0.9/apoc-3.5.0.9-all.jar -o /var/lib/neo4j/plugins/apoc-3.5.0.9-all.jar
sudo chown -R 101:101 /var/lib/neo4j/plugins


