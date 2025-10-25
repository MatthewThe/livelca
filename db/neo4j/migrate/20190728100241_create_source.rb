class CreateSource < ActiveGraph::Migrations::Base
  def up
    add_constraint :Source, :uuid
  end

  def down
    drop_constraint :Source, :uuid
  end
end
