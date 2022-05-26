class Tag 
  include Neo4j::ActiveNode
  property :name, type: String
  property :color, type: String
  property :category, type: String



end
