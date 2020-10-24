cd db/neo4j/development/data/databases/
zip -r graph_db graph.db
scp graph_db.zip livelca.us-east1-b.vibrant-tree-238320:~/
ssh livelca.us-east1-b.vibrant-tree-238320 ~/livelca/unpack_graph_db.sh
