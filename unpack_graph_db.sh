#sudo systemctl stop neo4j
sudo mkdir -p /var/lib/neo4j/data/databases
cd /var/lib/neo4j/data/databases
#sudo rm -rf graph.db.bak
#sudo mv graph.db/ graph.db.bak
#sudo unzip ~/graph_db.zip
#sudo chown neo4j:neo4j -R graph.db
#sudo systemctl start neo4j

sudo rm -rf graph.db

#sudo cp -r ~/Projects/livelca/db/neo4j/development/data/databases/graph.db ./graph.db

#sudo cp ~/Projects/livelca/db/neo4j/development/data/databases/graph.db.zip ./
sudo cp ~/graph.db.zip ./
sudo unzip graph.db.zip

sudo chown 101:101 -R graph.db
