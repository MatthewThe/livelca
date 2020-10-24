sudo apt-get install git docker.io

sudo usermod -aG docker ${USER}

sudo mkdir -p /var/lib/neo4j/data
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
