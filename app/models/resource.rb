class Resource 
  include Neo4j::ActiveNode
  property :name, type: String
  property :url, type: String
  property :notes, type: String, default: ""
  property :default_weight, type: Integer
  
  has_many :out, :sources, type: :IS_RESOURCE, model_class: :Source, dependent: :destroy
  
  def self.from_param(param)
    param[-36...]
  end
  
  def to_param
    "#{self.name.downcase.parameterize[...50]}_#{self.id}"
  end
  
  def self.find_or_create(resource_name, resource_url, resource_default_weight)
    if resource_name.length > 0
      resource = find_by(name: resource_name)
      if !resource
        resource = new(name: resource_name, url: resource_url, default_weight: resource_default_weight)
        resource.save
      end
      resource
    else
      nil
    end
  end
end
