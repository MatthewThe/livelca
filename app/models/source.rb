class Source 
  include ActiveGraph::Node
  include ActiveGraph::Timestamps # will give model created_at and updated_at timestamps
  
  after_save :update_product_co2_equiv
  
  property :name, type: String
  property :url, type: String
  property :co2_emission, type: Float
  property :ch4_emission, type: Float
  property :n2o_emission, type: Float
  property :co2_equiv, type: Float
  property :notes, type: String, default: ""
  property :weight, type: Integer

  has_one :out, :country_origin, type: :PRODUCED_IN, model_class: :Country
  has_one :out, :country_consumption, type: :CONSUMED_IN, model_class: :Country
  has_one :out, :product, type: :STUDY_FOR, model_class: :Product
  has_one :in, :resource, type: :IS_RESOURCE, model_class: :Resource
  
  def product_name
    product ? product.name : ""
  end
  
  def update_product_co2_equiv
    product.save # triggers recalculation of product's cached co2_equiv
  end
  
  def country_origin_name
    country_origin ? country_origin.name : "Unknown"
  end
  
  def country_consumption_name
    country_consumption ? country_consumption.name : "Unknown"
  end
  
  def co2_equiv_color
    co2_equiv_scaled = [0, [co2_equiv / 5, 1].min].max
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
end
