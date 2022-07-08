class Tag 
  include Neo4j::ActiveNode
  property :name, type: String
  property :color, type: String
  property :category, type: String

  has_many :in, :recipes, type: :HAS_TAG, model_class: :Recipe
  
  def to_param
    "#{self.name.downcase.parameterize[...50]}_#{self.id}"
  end
  
  def self.from_param(param)
    self.where(id: param[-36...]).first
  end

end
