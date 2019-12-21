class Source 
  include Neo4j::ActiveNode
  property :name, type: String
  property :url, type: String
  property :co2_emission, type: Float
  property :ch4_emission, type: Float
  property :n2o_emission, type: Float
  property :co2_equiv, type: Float
  property :notes, type: String
  property :weight, type: Integer

  has_one :out, :country_origin, type: :PRODUCED_IN, model_class: :Country
  has_one :out, :country_consumption, type: :CONSUMED_IN, model_class: :Country
  has_one :out, :product, type: :STUDY_FOR, model_class: :Product
  has_one :in, :resource, type: :IS_RESOURCE, model_class: :Resource
  
  def product_name
    product ? product.name : ""
  end
  
  def country_origin_name
    country_origin ? country_origin.name : "Unknown"
  end
  
  def country_consumption_name
    country_consumption ? country_consumption.name : "Unknown"
  end
end
