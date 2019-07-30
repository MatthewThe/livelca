class CreateCountry < Neo4j::Migrations::Base
  def up
    add_constraint :Country, :uuid
  end

  def down
    drop_constraint :Country, :uuid
  end
end
