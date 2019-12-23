class CreateIngredient < Neo4j::Migrations::Base
  def up
    add_constraint :Ingredient, :uuid
  end

  def down
    drop_constraint :Ingredient, :uuid
  end
end
