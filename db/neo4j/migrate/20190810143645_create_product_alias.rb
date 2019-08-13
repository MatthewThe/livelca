class CreateProductAlias < Neo4j::Migrations::Base
  def up
    add_constraint :ProductAlias, :uuid
  end

  def down
    drop_constraint :ProductAlias, :uuid
  end
end
