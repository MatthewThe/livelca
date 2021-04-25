class Recipe 
  include Neo4j::ActiveNode
  property :name, type: String
  property :servings, type: Float
  property :is_public, type: Boolean, default: true
  
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
  
  def co2_equiv_color
    self.class.co2_equiv_color_compute(co2_equiv_per_serving)
  end
  
  def self.co2_equiv_color_compute(co2_equiv_per_serving)
    co2_equiv_scaled = [0, [co2_equiv_per_serving / 5, 1].min].max
    green = [0,142,9]
    yellow = [255,191,0]
    red = [255,3,3]
    if co2_equiv_scaled < 0.5
      color = [green, yellow].transpose.map{|x| 2*(0.5 - co2_equiv_scaled) * x[0] + 2*co2_equiv_scaled * x[1]}
    else
      color = [yellow, red].transpose.map{|x| 2*(1.0 - co2_equiv_scaled) * x[0] + 2*(co2_equiv_scaled - 0.5) * x[1]}
    end
    "rgb(" + color[0].to_s + "," + color[1].to_s + "," + color[2].to_s + ")"
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
