json.extract! source, :id, :name, :url, :country_origin_id, :country_consumption_id, :co2_emission, :ch4_emission, :n2o_emission, :co2_equiv, :notes, :weight, :created_at, :updated_at
json.url source_url(source, format: :json)
