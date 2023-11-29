class Product 
  include Neo4j::ActiveNode
  include Neo4j::Timestamps # will give model created_at and updated_at timestamps
  
  before_save :set_co2_equiv
  after_update :update_proxies_co2_equiv, :update_recipes_co2_equiv
  
  property :name, type: String
  property :wiki, type: String, default: ""
  property :co2_equiv, type: Float, default: -1.0

  has_many :in, :studies, type: :STUDY_FOR, model_class: :Source, dependent: :destroy
  has_one :out, :category, type: :IS_SUBCATEGORY_OF, model_class: :Product
  has_many :in, :subcategories, type: :IS_SUBCATEGORY_OF, model_class: :Product
  has_one :out, :proxy, type: :USE_AS_PROXY, model_class: :Product
  
  has_many :in, :proxy_for, type: :USE_AS_PROXY, model_class: :Product
  has_many :in, :ingredients, type: :IS_PRODUCT, model_class: :Ingredient
  
  def self.from_param(param)
    param[-36...]
  end
  
  def to_param
    "#{self.name.downcase.parameterize[...50]}_#{self.id}"
  end
  
  # class method
  def self.get_random
    self.as('r')
        .order("(id(r) * (datetime.truncate('day', datetime()).epochMillis / 86400000)) % 1013")
        .with_associations(:proxy, :studies, :subcategories)
        .limit(1)
        .first
  end
  
  def set_co2_equiv
    self.co2_equiv = compute_co2_equiv
  end
  
  def update_proxies_co2_equiv
    proxy_for.each do |p|
      p.update({})
    end
  end
  
  def update_recipes_co2_equiv
    ingredients.each do |i|
      i.update({}) # this will trigger the recipe.save method
    end
  end
  
  def description
    description = "Product: " + name + "\n"\
       + "Category: " + (category ? category.name : "-") + "\n"\
       + "You can consume " + (2.7 / co2_equiv).round(2).to_s + " kg of " + name + " to exhaust your daily CO2e food budget" + "\n"\
       + "Emissions per kg: " + co2_equiv.to_s + " kg CO2e" + "\n"\
       + "Number of studies included: " + study_count.to_s
  end
  
  def study_count
    count = 0
    studies.each do |s|
      if s.weight > 0
        count += 1
      end
    end
    count
  end
  
  def subcategories_count
    count = 0
    subcategories.each do |s|
      count += 1
    end
    count
  end
  
  def compute_co2_equiv
    if study_count > 0
      weightSum = 0
      weightedSum = 0.0
      studies.each do |s|
        weightedSum += s.co2_equiv * s.weight
        weightSum += s.weight
      end
      (weightedSum / weightSum).round(3)
    elsif proxy
      proxy.co2_equiv
    else
      1.0
    end
  end
  
  def co2_equiv_color
    co2_equiv_scaled = [0, [co2_equiv / 5, 1].min].max
    green = [0,142,9]
    yellow = [255,191,0]
    red = [255,3,3]
    if co2_equiv_scaled < 0.5
      color = [green, yellow].transpose.map{|x| 2*(0.5 - co2_equiv_scaled) * x[0] + 2*co2_equiv_scaled * x[1]}
    else
      color = [yellow, red].transpose.map{|x| 2*(1.0 - co2_equiv_scaled) * x[0] + 2*(co2_equiv_scaled - 0.5) * x[1]}
    end
    "rgb(" + color[0].to_s + "," + color[1].to_s + "," + color[2].to_s + ")"
  end
  
  def reliability_class
    if study_count > 0
      'reliable'
    elsif proxy
      'proxy'
    else
      'unreliable'
    end
  end
      
    
  def get_super_categories
    query_as(:leaf)
        .match('path = (leaf:Product)-[:IS_SUBCATEGORY_OF*]->(root:Product)')
        .where('NOT (root)-[:IS_SUBCATEGORY_OF]->()')
        .with('nodes(path) AS supercategory_list')
        .unwind('supercategory_list AS supercategories')
        .skip(1)
        .pluck(:supercategories)
  end
  
  def self.search(term)
    where(name: /#{Regexp.escape(term)}.*/i)
  end
  
  def self.find_or_create(product_name)
    if product_name.length > 0
      product = find_by(name: product_name)
      if !product
        product = new(name: product_name)
        product.save
      end
      product
    else
      nil
    end
  end
  
  def with_name
    attributes.slice("name")
  end
  
  def self.traverse_tree(root, levels=2)
    products = [root]
    products_current_level = [root]
    for level in 1..levels
        products_next_level = []
        for product in products_current_level
            products_next_level.concat product.subcategories
            products.concat product.subcategories
        end
        products_current_level = products_next_level
    end
    products
  end
  
  def get_graph_node_info
    with_name.merge({:co2_equiv_color => co2_equiv_color, 
                     :co2_equiv => co2_equiv,
                     :to_param => to_param})
  end
  
  def get_graph_tree(supercategories)
    product_tree = []
    supercategories.each_with_index do |p, i|
      if i == 0 
        # the direct parent of the current product
        product_tree.push({:product => p.with_name.merge(:subcategories => [with_name])})
      else 
        # higher-level parents
        product_tree.push({:product => p.with_name.merge(:subcategories => [supercategories[i-1].with_name])})
      end
    end
    # the subcategories of the current product
    product_tree.push({:product => with_name.merge(:subcategories => subcategories.map{|p| p.with_name})})
    product_tree.to_json()
  end
  
  def get_graph_nodes(products)
    products_with_co2 = products.map{|p| {:product => p.get_graph_node_info} }
    products_with_co2.to_json()
  end
  
  def self.name_from_id(product_id)
    product_name = ""
    product = find_by(id: product_id)
    if product
      product_name = product.name
    end
    product_name
  end
  
  def self.add_product_query(item, queries)
    search_term = item.gsub(/[^0-9A-Za-z ]/, '').strip().gsub(/\s+/, '~ ') + "~"
    queries.append search_term
  end
  
  def self.run_products_query(queries)
    results = Neo4j::ActiveBase.current_session.queries do
      queries.each do |query|
        append "CALL db.index.fulltext.queryNodes('productNames', {item})
          YIELD node AS productAlias
          MATCH (p)
          WHERE (productAlias)-[:IS_ALIAS]->(p:Product)
          RETURN p.name
          LIMIT {limit}", item: query, limit: 1
      end
    end
  end
  
  def merge_with(other_product_name)
    Neo4j::ActiveBase.current_session.query("MATCH (p1:Product), (p2:Product)
      WHERE p1.name = {p1_name} AND p2.name = {p2_name}
      call apoc.refactor.mergeNodes([p2,p1]) YIELD node
      RETURN node", p1_name: name, p2_name: other_product_name)
  end
  
  def self.get_product_tree(root)
    #results = self.all.with_associations(:subcategories).to_json(:include => :subcategories)
    results = ([self.find_by(name: root)] + self.find_by(name: root).subcategories.with_associations(:subcategories)).to_json(:include => :subcategories)
  end
  
  def proxy_name
    proxy ? proxy.name : ""
  end
  
  def category_name
    category ? category.name : ""
  end
  
  attr_accessor :merge_product_name

end
