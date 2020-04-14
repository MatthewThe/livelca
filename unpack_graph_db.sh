sudo systemctl stop neo4j
cd /var/lib/neo4j/data/databases
sudo rm -rf graph.db.bak
sudo mv graph.db/ graph.db.bak
sudo unzip ~/graph_db.zip
sudo chown neo4j:neo4j -R graph.db
sudo systemctl start neo4j
