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
  
  def self.find_or_create(alias_name)
    if alias_name.length > 0
      product_alias = find_by(name: alias_name)
      if !product_alias
        product_alias = new(name: alias_name)
        product_alias.save
      end
      product_alias
    else
      nil
    end
  end

end
