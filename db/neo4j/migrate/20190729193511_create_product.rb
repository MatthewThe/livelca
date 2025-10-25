class CreateProduct < ActiveGraph::Migrations::Base
  def up
    add_constraint :Product, :uuid
  end

  def down
    drop_constraint :Product, :uuid
  end
end
