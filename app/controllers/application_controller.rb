class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def is_admin
    unless current_user.admin?
      flash[:error] = "You must be an administrator to access this section"
      redirect_to new_user_session_path # halts request cycle
    end
  end
end
