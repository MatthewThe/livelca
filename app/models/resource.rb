class Resource 
  include Neo4j::ActiveNode
  
  enum peer_reviewed: {
    no: 0,
    yes: 1,
  }, _prefix: :peer_reviewed, _index: false
  property :peer_reviewed, default: Resource.peer_revieweds[:yes]
  
  enum num_products: {
    below_5: 0,
    below_10: 1,
    above_10: 2,
  }, _prefix: :num_products, _index: false
  property :num_products, default: Resource.num_products[:below_5]
  
  enum meta_study: {
    no: 0,
    yes: 1,
  }, _prefix: :meta_study, _index: false
  property :meta_study, default: Resource.meta_studies[:no]
  
  enum commissioned: {
    no: 0,
    partial: 1,
    yes: 2,
  }, _prefix: :commissioned, _index: false
  property :commissioned, default: Resource.commissioneds[:no]
  
  enum year_of_study: {
    before_2005: 0,
    after_2005: 1,
  }, _prefix: :year_of_study, _index: false
  property :year_of_study, default: Resource.year_of_studies[:after_2005]
  
  enum methodology_described: {
    no: 0,
    partial: 1,
    yes: 2,
  }, _prefix: :methodology_described, _index: false
  property :methodology_described, default: Resource.methodology_describeds[:yes]
  
  enum source_reputation: {
    low: 0,
    medium: 1,
    high: 2,
  }, _prefix: :source_reputation, _index: false
  property :source_reputation, default: Resource.source_reputations[:high]
  
  property :name, type: String
  property :url, type: String
  property :notes, type: String, default: ""
  property :default_weight, type: Integer
  
  has_many :out, :sources, type: :IS_RESOURCE, model_class: :Source, dependent: :destroy
  
  before_save :calculate_default_weight
  
  def self.from_param(param)
    param[-36...]
  end
  
  def to_param
    "#{self.name.downcase.parameterize[...50]}_#{self.id}"
  end
  
  def calculate_default_weight
    default_weight = 10
    
    if self.peer_reviewed_no?
      default_weight -= 2
    end
    
    if self.num_products_above_10?
      default_weight -= 2
    end
    
    if self.commissioned_partial?
      default_weight -= 2
    end
    
    if self.commissioned_yes?
      default_weight -= 5
    end
    
    if self.year_of_study_before_2005?
      default_weight -= 3
    end
    
    if self.methodology_described_partial?
      default_weight -= 1
    end
    
    if self.methodology_described_no?
      default_weight -= 3
    end
    
    if self.source_reputation_low?
      default_weight -= 3
    end
    
    old_default_weight = self.default_weight
    self.default_weight = [default_weight, 0].max
    
    if old_default_weight != self.default_weight
      self.sources.where(weight: old_default_weight).update_all(weight: self.default_weight)
    end
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
