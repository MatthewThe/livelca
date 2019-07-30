class CreateReceipt < Neo4j::Migrations::Base
  def up
    add_constraint :Receipt, :uuid
  end

  def down
    drop_constraint :Receipt, :uuid
  end
end
