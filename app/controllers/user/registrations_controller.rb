# frozen_string_literal: true

class User::RegistrationsController < Devise::RegistrationsController
  #before_action :configure_sign_up_params, only: [:create]
  #before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  #def new
  #   super
  #end

  # POST /resource
  #def create
  #  super 
  #end

  #GET /resource/edit
  def edit
    @country_name = ""
    if resource.country
      @country_name = resource.country.name
    end
    super
  end

  #PUT /resource
  #def update
    #super
  #end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  #def configure_sign_up_params
  #  devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :country_name])
  #end

  # If you have extra params to permit, append them to the sanitizer.
  #def configure_account_update_params
  #  devise_parameter_sanitizer.permit(:account_update, keys: [:name, :country_name])
  #end
  
  private
    def sign_up_params
      a = params.require(:user).permit(:name, :email, :password, :password_confirmation, :country_name)
      a[:country] = get_country(a[:country_name])
      a.delete(:country_name)
      a
    end
    
    def account_update_params
      a = params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password, :country_name, :admin)
      a[:country] = get_country(a[:country_name])
      a.delete(:country_name)
      a
    end
  
    def get_country(country_name)
      country = Country.find_by(name: country_name)
      if !country
        country = Country.new(name: country_name)
        country.save
      end
      country
    end
  
  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
