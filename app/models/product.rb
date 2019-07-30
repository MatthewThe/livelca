class Product 
  include Neo4j::ActiveNode
  property :name, type: String
  property :wiki, type: String, default: ""

  has_many :in, :studies, type: :STUDY_FOR, model_class: :Source, dependent: :destroy
  has_one :out, :category, type: :IS_SUBCATEGORY_OF, model_class: :Product
  has_one :out, :proxy, type: :USE_AS_PROXY, model_class: :Product
  
  def co2_equiv
    if self.studies.count > 0
      weightSum = 0
      weightedSum = 0.0
      for s in self.studies do
        weightedSum += s.co2_equiv * s.weight
        weightSum += s.weight
      end
      (weightedSum / weightSum).round(3)
    elsif self.proxy
      self.proxy.co2_equiv
    else
      0.0
    end
  end
  
  def self.search(term)
    where(name: /#{term}.*/i)
  end
  
  def self.get_name(product_id)
    product_name = ""
    product = find_by(id: product_id)
    if product
      product_name = product.name
    end
    product_name
  end

end
