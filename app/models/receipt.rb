class Receipt 
  include Neo4j::ActiveNode
  property :date, type: DateTime
  property :store, type: String

  has_many :out, :purchases, type: :IS_PURCHASE, model_class: :Purchase, dependent: :destroy
  has_one :out, :user, type: :IS_OWNED, model_class: :User
  
  def co2_equiv
    co2_sum = 0.0
    for p in self.purchases
      co2_sum += p.weight * p.product.co2_equiv
    end
    co2_sum.round(3)
  end

end
