class CreateTag < Neo4j::Migrations::Base
  def up
    add_constraint :Tag, :uuid
  end

  def down
    drop_constraint :Tag, :uuid
  end
end
