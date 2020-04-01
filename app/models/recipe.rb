class Recipe 
  include Neo4j::ActiveNode
  property :name, type: String
  property :servings, type: Float
  
  has_one :out, :user, type: :IS_OWNED, model_class: :User
  has_many :in, :ingredients, type: :IS_INGREDIENT, model_class: :Ingredient, dependent: :destroy
  has_one :out, :country_consumption, type: :CONSUMED_IN, model_class: :Country
  
  def co2_equiv
    co2_sum = 0.0
    for p in ingredients
      co2_sum += p.weight * p.product.co2_equiv
    end
    co2_sum.round(3)
  end
  
  def co2_equiv_per_serving
    (co2_equiv / servings).round(3)
  end
  
  def ingredients_list
    ingredients_text = ""
    for i in ingredients
      if i.description.empty?
        ingredients_text += i.weight.to_s + " kg " + i.product.name + "\n"
      else
        ingredients_text += i.description + "\n"
      end
    end
    ingredients_text
  end

end
