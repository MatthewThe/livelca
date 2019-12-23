class Ingredient 
  include Neo4j::ActiveNode
  property :weight, type: Float

  has_one :out, :product, type: :IS_PRODUCT, model_class: :Product
  has_one :out, :recipe, type: :IS_INGREDIENT, model_class: :Recipe
  has_one :out, :country_origin, type: :PRODUCED_IN, model_class: :Country
  
  def product_name
    product ? product.name : ""
  end
  
  def country_origin_name
    country_origin ? country_origin.name : "Unknown"
  end
  
  def self.parse(s)
    amount = 1.0
    mult = 1.0
    item = ""
    
    m = /\s*([0-9\/.]*)?\s*(tablespoon|tbsp|teaspoon|tsp|pound|lb|oz|ounce|cup|can|slice|clove|kg|gr|g|ml|l)?[s]?\s*(.*)/.match(s)
    if m and m.length >= 3
      if /\//.match(m[1])
        amount = m[1].to_r
      elsif m[1].length > 0
        amount = m[1].to_f
      end
      
      if /^(kg|l)$/.match(m[2])
        mult = 1.0
      elsif /^(dl)$/.match(m[2])
        mult = 0.1
      elsif /^(gr|g|ml)$/.match(m[2])
        mult = 0.001
      elsif /^(tbsp|tablespoon[s]?)$/.match(m[2])
        mult = 0.015
      elsif /^(tsp|teaspoon[s]?)$/.match(m[2])
        mult = 0.005
      elsif /^(lb|pound[s]?)$/.match(m[2])
        mult = 0.450
      elsif /^(oz|ounce[s]?)$/.match(m[2])
        mult = 0.028
      elsif /^(cup[s]?)$/.match(m[2])
        mult = 0.2
      elsif /^(clove[s]?)$/.match(m[2])
        mult = 0.015
      elsif /^(slice[s]?)$/.match(m[2])
        mult = 0.012
      elsif /^(can[s]?)$/.match(m[2])
        mult = 0.4
      elsif /onion[s]?/.match(m[3])
        mult = 0.2
      elsif /carrot[s]?$/.match(m[3])
        mult = 0.07
      end
      item = m[3]
    end
    return (amount*mult).round(3), item
  end
  
end
