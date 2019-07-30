json.extract! purchase, :id, :product_id, :weight, :receipt_id, :created_at, :updated_at
json.url purchase_url(purchase, format: :json)
