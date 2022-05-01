class Ingredient 
  include Neo4j::ActiveNode
  property :weight, type: Float
  property :description, type: String, default: ""

  has_one :out, :product, type: :IS_PRODUCT, model_class: :Product
  has_one :out, :recipe, type: :IS_INGREDIENT, model_class: :Recipe
  has_one :out, :country_origin, type: :PRODUCED_IN, model_class: :Country
  
  def product_name
    product ? product.name : ""
  end
  
  def country_origin_name
    country_origin ? country_origin.name : "Unknown"
  end
  
  def co2_equiv
    (weight * product.co2_equiv).round(3)
  end
  
  def co2_equiv_color(servings)
    co2_equiv_scaled = [0, [co2_equiv / servings * 2, 1].min].max
    green = [0,142,9]
    yellow = [255,191,0]
    red = [255,3,3]
    if co2_equiv_scaled < 0.5
      color = [green, yellow].transpose.map{|x| 2*(0.5 - co2_equiv_scaled) * x[0] + 2*co2_equiv_scaled * x[1]}
    else
      color = [yellow, red].transpose.map{|x| 2*(1.0 - co2_equiv_scaled) * x[0] + 2*(co2_equiv_scaled - 0.5) * x[1]}
    end
    "rgb(" + color[0].round(1).to_s + "," + color[1].round(1).to_s + "," + color[2].round(1).to_s + ")"
  end
  
  def self.parse(s)
    amount = -1
    mult = -1
    item = ""
    
    # use https://regex101.com/ for testing this regex
    m = /([0-9\/.\s]*)?\s*[(x]?([0-9\/.\s]*)?(tablespoon|tbsp|teaspoon|tsp|pound|lb|oz|ounce|cup|can|slice|clove|pinch|kg|gr|g|dl|ml|l)?(?:[s]+\s+)?[(]?[)]?(.*)/.match(s.downcase.strip.gsub('.', ''))
    if m and m.length >= 4
      puts "hello"
      puts m[2]
      if m[1].length > 0
        amount = mixed_number_to_rational(m[1])
      end
      
      if m[2].length > 0
        amount *= mixed_number_to_rational(m[2])
      end
      
      unit = m[3]
      item = m[4]
      # regex cheatsheet: "^": start of line, "$": end of line, "\b": word boundary (space or new line)
      if /^(kg|l)$/.match(unit)
        mult = 1.0
      elsif /^(dl)$/.match(unit)
        mult = 0.1
      elsif /^(gr|g|ml)$/.match(unit)
        mult = 0.001
      elsif /^(tbsp|tablespoon[s]?)$/.match(unit)
        mult = 0.015
      elsif /^(tsp|teaspoon[s]?)$/.match(unit)
        mult = 0.005
      elsif /^(lb|pound[s]?)$/.match(unit)
        mult = 0.450
      elsif /^(oz|ounce[s]?)$/.match(unit)
        mult = 0.028
      elsif /^(cup[s]?)$/.match(unit)
        mult = 0.2
      elsif /^(clove[s]?)$/.match(unit)
        mult = 0.015
      elsif /^(slice[s]?)$/.match(unit)
        mult = 0.012
      elsif /^(can[s]?)$/.match(unit)
        mult = 0.4
      elsif /\bonion[s]?\b/.match(item)
        mult = 0.2
      elsif /\bcarrot[s]?\b/.match(item)
        mult = 0.07
      elsif /\begg[s]?\b/.match(item)
        mult = 0.06
      elsif /\bsalt\b/.match(item)
        mult = 0.001
      elsif /\bpepper\b/.match(item)
        mult = 0.001
      elsif /\boil\b/.match(item)
        mult = 0.015
      elsif /\bbay lea(f|ves)?\b/.match(item)
        mult = 0.001
      elsif /\bcan[s]?\b/.match(item)
        mult = 0.4
      elsif /^(pinch)$/.match(unit)
        mult = 0.001
      end
      
    end
    
    if amount == -1
      if mult == -1
        amount = 0.1
        mult = 1.0
      else
        amount = 1.0
      end
    elsif mult == -1
      mult = 1.0
    end
    
    return (amount*mult).round(3), item
  end
  
  def self.is_rational?(object)
    true if Rational(object) rescue false
  end
   
  # http://aspiringwebdev.com/mixed-numbers-in-ruby-rails/
  def self.mixed_number_to_rational(amount)
    rational_to_return = 0
    amount.split(" ").each { |string|
      if is_rational?(string) # Number?
        if string.include?("/") # Fraction?
          rational_to_return += Rational(string)
        elsif string.to_i == string.to_f # Whole number?
          rational_to_return += string.to_i
        elsif string.include?(".") # Decimal?
          rational_to_return += Rational(string)
        else # Not a fraction, decimal, or whole number.
          return false
        end
      else
        return false # Not a number.
      end
    }
    rational_to_return
  end
  
end
