class AddProductNameIndex < Neo4j::Migrations::Base
  def up
    execute 'CALL db.index.fulltext.createNodeIndex("productNames",["Product", "ProductAlias"],["name"])'
  end

  def down
    execute 'CALL db.index.fulltext.drop("productNames")'
  end
end
