class Recipe 
  include Neo4j::ActiveNode
  include Neo4j::Timestamps # will give model created_at and updated_at timestamps
  
  before_save :update_instructions, :set_co2_equiv
  
  property :name, type: String
  property :servings, type: Float
  property :is_public, type: Boolean, default: true
  property :co2_equiv, type: Float, default: -1.0
  
  property :url, type: String
  property :description, type: String, default: ""
  property :instructions, type: String, default: ""
  
  has_one :out, :user, type: :IS_OWNED, model_class: :User
  has_many :in, :ingredients, type: :IS_INGREDIENT, model_class: :Ingredient, dependent: :destroy
  has_one :out, :country_consumption, type: :CONSUMED_IN, model_class: :Country
  has_many :out, :tags, type: :HAS_TAG, model_class: :Tag
  
  def to_param
    "#{name.downcase.parameterize[...50]}_#{id}"
  end
  
  # class method
  def self.from_param(param)
    param[-36...]
  end
  
  # class method
  def self.get_random
    self.as('r')
        .order("(id(r) * (datetime.truncate('day', datetime()).epochMillis / 86400000)) % 1013")
        .with_associations(:country_consumption, :ingredients => [:country_origin, :product => [:studies, :proxy => [:studies]]])
        .limit(1)
        .first
  end
  
  def meta_description
    "Recipe: " + name + ' '\
       + description + ' '\
       + "You can eat " + (2.7 / co2_equiv_per_serving).round(2).to_s + " servings of " + name + " to exhaust your daily CO2e food budget" + ' '\
       + "Emissions per serving: " + co2_equiv_per_serving.to_s + " kg CO2e"
  end
  
  def set_co2_equiv
    self.co2_equiv = compute_co2_equiv
  end
  
  def compute_co2_equiv
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
  
  # class method
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
  
  def update_instructions
    if instructions
      # remove empty lines
      instruction_list = []
      for row in self.instructions.split("\n")
        line = row.strip
        if line.length > 0
          instruction_list.push(line)
        end
      end
      self.instructions = instruction_list.join("\n")
    end
  end
end
