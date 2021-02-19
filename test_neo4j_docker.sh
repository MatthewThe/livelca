docker run \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=/var/lib/neo4j/data:/data \
    --env NEO4J_dbms_memory_heap_max__size=64m \
    --env NEO4J_dbms_memory_pagecache_size=64m \
    neo4j:3.5.14

