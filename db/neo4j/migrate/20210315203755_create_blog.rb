class CreateBlog < ActiveGraph::Migrations::Base
  def up
    add_constraint :Blog, :uuid
  end

  def down
    drop_constraint :Blog, :uuid
  end
end
