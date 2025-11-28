class Resource 
  include ActiveGraph::Node
  
  enum peer_reviewed: {
    no: 0,
    yes: 1,
  }, _prefix: :peer_reviewed, _index: false
  property :peer_reviewed, default: Resource.peer_revieweds[:yes]
  PEER_REVIEWED_PENALTY = { "no" => 2, "yes" => 0 }
  
  enum num_products: {
    below_5: 0,
    below_10: 1,
    above_10: 2,
  }, _prefix: :num_products, _index: false
  property :num_products, default: Resource.num_products[:below_5]
  NUM_PRODUCTS_PENALTY = { "below_5" => 0, "below_10" => 0, "above_10" => 2 }
  
  enum meta_study: {
    no: 0,
    yes: 1,
  }, _prefix: :meta_study, _index: false
  property :meta_study, default: Resource.meta_studies[:no]
  META_STUDY_PENALTY = { "no" => 0, "yes" => 0 }
  
  enum commissioned: {
    no: 0,
    partial: 1,
    yes: 2,
  }, _prefix: :commissioned, _index: false
  property :commissioned, default: Resource.commissioneds[:no]
  COMMISSIONED_PENALTY = { "no" => 0, "partial" => 2, "yes" => 5 }
  
  enum year_of_study: {
    before_2005: 0,
    after_2005: 1,
  }, _prefix: :year_of_study, _index: false
  property :year_of_study, default: Resource.year_of_studies[:after_2005]
  YEAR_OF_STUDY_PENALTY = { "before_2005" => 2, "after_2005" => 0 }
  
  enum methodology_described: {
    no: 0,
    partial: 1,
    yes: 2,
  }, _prefix: :methodology_described, _index: false
  property :methodology_described, default: Resource.methodology_describeds[:yes]
  METHODOLOGY_DESCRIBED_PENALTY = { "no" => 3, "partial" => 1, "yes" => 0 }
  
  enum source_reputation: {
    low: 0,
    medium: 1,
    high: 2,
  }, _prefix: :source_reputation, _index: false
  property :source_reputation, default: Resource.source_reputations[:high]
  SOURCE_REPUTATION_PENALTY = { "low" => 3, "medium" => 0, "high" => 0 }
  
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

    default_weight -= PEER_REVIEWED_PENALTY[self.peer_reviewed.to_s]
    default_weight -= NUM_PRODUCTS_PENALTY[self.num_products.to_s]
    default_weight -= META_STUDY_PENALTY[self.meta_study.to_s]
    default_weight -= COMMISSIONED_PENALTY[self.commissioned.to_s]
    default_weight -= YEAR_OF_STUDY_PENALTY[self.year_of_study.to_s]
    default_weight -= METHODOLOGY_DESCRIBED_PENALTY[self.methodology_described.to_s]
    default_weight -= SOURCE_REPUTATION_PENALTY[self.source_reputation.to_s]
    
    old_default_weight = self.default_weight
    self.default_weight = [default_weight, 0].max
    
    if old_default_weight != self.default_weight
      self.sources.where(weight: old_default_weight).update_all(weight: self.default_weight)
    end
  end
  
  def peer_reviewed_penalty_string
    penalty = PEER_REVIEWED_PENALTY[self.peer_reviewed.to_s]
    to_penalty_string penalty
  end
  
  def num_products_penalty_string
    penalty = NUM_PRODUCTS_PENALTY[self.num_products.to_s]
    to_penalty_string penalty
  end
  
  def meta_study_penalty_string
    penalty = META_STUDY_PENALTY[self.meta_study.to_s]
    to_penalty_string penalty
  end
  
  def commissioned_penalty_string
    penalty = COMMISSIONED_PENALTY[self.commissioned.to_s]
    to_penalty_string penalty
  end
  
  def year_of_study_penalty_string
    penalty = YEAR_OF_STUDY_PENALTY[self.year_of_study.to_s]
    to_penalty_string penalty
  end
  
  def methodology_described_penalty_string
    penalty = METHODOLOGY_DESCRIBED_PENALTY[self.methodology_described.to_s]
    to_penalty_string penalty
  end
  
  def source_reputation_penalty_string
    penalty = SOURCE_REPUTATION_PENALTY[self.source_reputation.to_s]
    to_penalty_string penalty
  end
  
  def to_penalty_string(penalty)
    if penalty > 0
      "(" + penalty.to_s + " penalty points)"
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
