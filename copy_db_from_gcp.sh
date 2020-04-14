rake neo4j:stop
cd db/neo4j/development/data/databases/
ssh neo4j-livelca.us-east1-b.vibrant-tree-238320 ~/pack_graph_db.sh
scp neo4j-livelca.us-east1-b.vibrant-tree-238320:~/graph_db.zip ./
sudo rm -rf graph.db.bak
sudo mv graph.db/ graph.db.bak
sudo unzip graph_db.zip
#sudo chown neo4j:neo4j -R graph.db
cd ../../../../../
rake neo4j:start
