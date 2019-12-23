class CreateResource < Neo4j::Migrations::Base
  def up
    add_constraint :Resource, :uuid
  end

  def down
    drop_constraint :Resource, :uuid
  end
end
