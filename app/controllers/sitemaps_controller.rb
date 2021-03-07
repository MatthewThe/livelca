class SitemapsController < ApplicationController
  def index
    @host = "#{request.protocol}#{request.host}"
    
    @products = Product.all
    @recipes = Recipe.where(is_public: true)
    @resources = Resource.all
  end
end
