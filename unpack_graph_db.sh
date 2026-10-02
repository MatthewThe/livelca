#sudo systemctl stop neo4j
docker stop livelca_database_1
sudo mkdir -p /var/lib/neo4j/data/databases
cd /var/lib/neo4j/data/databases
sudo rm -rf graph.db.bak
sudo mv graph.db/ graph.db.bak
sudo unzip /home/matthewt/graph_db.zip
#sudo chown neo4j:neo4j -R graph.db
sudo chown 101:101 -R graph.db
#sudo systemctl start neo4j
docker start livelca_database_1