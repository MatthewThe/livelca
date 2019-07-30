class CreatePurchase < Neo4j::Migrations::Base
  def up
    add_constraint :Purchase, :uuid
  end

  def down
    drop_constraint :Purchase, :uuid
  end
end
