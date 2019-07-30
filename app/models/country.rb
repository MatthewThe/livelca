class Country 
  include Neo4j::ActiveNode
  property :name, type: String

  def self.search(term)
    where(name: /#{term}.*/i)
  end

end
