class Country 
  include ActiveGraph::Node
  property :name, type: String
  property :wiki, type: String, default: ""

  def self.search(term)
    where(name: /#{term}.*/i)
  end
  
  def self.find_or_create(country_name)
    if country_name.length == 0
      country_name = "Unknown"
    end
    
    country = find_by(name: country_name)
    if !country
      country = new(name: country_name)
      country.save
    end
    country
  end
  
  def self.name_from_id(id)
    country_origin_name = ""
    country_origin = find_by(id: id)
    if country_origin
      country_origin_name = country_origin.name
    end
    country_origin_name
  end
  
  def name_or_unknown
    if name
      name
    else
      "Unknown"
    end
  end

end
