cd db/neo4j/development/data/databases/
zip -r graph_db graph.db
scp graph_db.zip neo4j-livelca.us-east1-b.vibrant-tree-238320:~/
ssh neo4j-livelca.us-east1-b.vibrant-tree-238320 ~/unpack_graph_db.sh
