remote=hetzner
#remote=neo4j-livelca.us-east1-b.vibrant-tree-238320

bundle exec rake neo4j:stop
cd db/neo4j/development/data/databases/
ssh ${remote} ~/livelca/pack_graph_db.sh
scp ${remote}:~/graph_db.zip ./
sudo rm -rf graph.db.bak
sudo mv graph.db/ graph.db.bak
sudo unzip graph_db.zip
sudo chown matthewt:matthewt -R graph.db
cd ../../../../../
bundle exec rake neo4j:start
