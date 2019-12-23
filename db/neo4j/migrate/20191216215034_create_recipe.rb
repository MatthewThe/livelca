class CreateRecipe < Neo4j::Migrations::Base
  def up
    add_constraint :Recipe, :uuid
  end

  def down
    drop_constraint :Recipe, :uuid
  end
end
