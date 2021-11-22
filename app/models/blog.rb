class Blog 
  include Neo4j::ActiveNode
  include Neo4j::Timestamps # will give model created_at and updated_at timestamps
  
  property :title, type: String
  property :state, type: String, default: "draft"
  property :post, type: String, default: ""
  property :published_at, type: DateTime
  
  has_one :out, :user, type: :PUBLISHED_BY, model_class: :User
  
  def self.from_param(param)
    param[-36...]
  end
  
  def to_param
    "#{self.title.downcase.parameterize[...50]}_#{self.id}"
  end
end
