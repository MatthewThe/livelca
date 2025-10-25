class DeviseCreateUserConstraintsAndIndexes < ActiveGraph::Migrations::Base
  def up
    add_index :User, :email, force: true
    add_index :User, :remember_token, force: true
    add_index :User, :reset_password_token, force: true
    # add_index :User, :confirmation_token, force: true
    # add_index :User, :unlock_token, force: true
    # add_index :User, :authentication_token, force: true
  end
  
  def down
    drop_index :User, :email, force: true
    drop_index :User, :remember_token, force: true
    drop_index :User, :reset_password_token, force: true
    # add_index :User, :confirmation_token, force: true
    # add_index :User, :unlock_token, force: true
    # add_index :User, :authentication_token, force: true
  end
end
