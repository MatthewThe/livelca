class Product 
  include Neo4j::ActiveNode
  property :name, type: String
  property :wiki, type: String, default: ""

  has_many :in, :studies, type: :STUDY_FOR, model_class: :Source, dependent: :destroy
  has_one :out, :category, type: :IS_SUBCATEGORY_OF, model_class: :Product
  has_many :in, :subcategories, type: :IS_SUBCATEGORY_OF, model_class: :Product
  has_one :out, :proxy, type: :USE_AS_PROXY, model_class: :Product
  
  def study_count
    count = 0
    studies.each do |s|
      count += 1
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
  
  def co2_equiv
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
    where(name: /#{term}.*/i)
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
  
  def self.name_from_id(product_id)
    product_name = ""
    product = find_by(id: product_id)
    if product
      product_name = product.name
    end
    product_name
  end
  
  def self.add_product_query(item, queries)
    search_term = item.strip().gsub(/[^0-9A-Za-z ]/, '').gsub(/\s+/, '~ ') + "~"
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
  
  def self.get_product_tree
    results = self.all.with_associations(:proxy, :subcategories)
  end
  
  def as_json(options = {})
     {:product => attributes.merge({:subcategories => subcategories, :co2_equiv => co2_equiv_color})}
  end
  
  def proxy_name
    proxy ? proxy.name : ""
  end
  
  def category_name
    category ? category.name : ""
  end

end
