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
  
  def respond_to_format
    respond_to do |format|
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
      
      format.js {render layout: false}
      format.html {render :index, layout: true}
    end
  end
end
