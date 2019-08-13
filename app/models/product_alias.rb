class ProductAlias 
  include Neo4j::ActiveNode
  property :name, type: String

  has_one :out, :country, type: :PURCHASED_IN, model_class: :Country
  has_one :out, :product, type: :IS_ALIAS, model_class: :Product
  
  def product_name
    product ? product.name : ""
  end
  
  def country_name
    country ? country.name : "Unknown"
  end


end
