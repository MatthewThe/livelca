remote=hetzner
#remote=neo4j-livelca.us-east1-b.vibrant-tree-238320

rake neo4j:stop
cd db/neo4j/development/data/databases/
ssh ${remote} ~/livelca/pack_graph_db.sh
scp ${remote}:~/graph_db.zip ./
sudo rm -rf graph.db.bak
sudo mv graph.db/ graph.db.bak
sudo unzip graph_db.zip
#sudo chown neo4j:neo4j -R graph.db
cd ../../../../../
rake neo4j:start
