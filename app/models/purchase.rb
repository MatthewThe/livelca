class Purchase 
  include Neo4j::ActiveNode
  property :weight, type: Float

  has_one :out, :product, type: :IS_PRODUCT, model_class: :Product
  has_one :in, :receipt, type: :IS_PURCHASE, model_class: :Receipt


end
