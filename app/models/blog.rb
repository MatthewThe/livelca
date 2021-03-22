class Blog 
  include Neo4j::ActiveNode
  include Neo4j::Timestamps # will give model created_at and updated_at timestamps
  
  property :title, type: String
  property :state, type: String, default: "draft"
  property :post, type: String, default: ""
  property :published_at, type: DateTime
  
  has_one :out, :user, type: :PUBLISHED_BY, model_class: :User
end
