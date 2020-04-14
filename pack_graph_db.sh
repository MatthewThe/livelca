sudo systemctl stop neo4j
cd /var/lib/neo4j/data/databases
sudo zip -r graph_db graph.db
sudo cp graph_db.zip ~/
sudo systemctl start neo4j
