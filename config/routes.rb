Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root to: 'products#index'
  
  resources :tags
  resources :blogs
  resources :ingredients
  resources :recipes
  resources :resources
  resources :product_aliases  
  resources :products
  resources :countries
  resources :sources
  resources :receipts
  resources :purchases
  #resources :users
  
  devise_for :users, controllers: {
    #sessions: 'users/sessions'
    registrations: 'user/registrations'
  }
  
  scope "/admin" do
    resources :users
  end
  
  get '/country_autocomplete' => 'countries#autocomplete'
  get '/product_autocomplete' => 'products#autocomplete'
  get '/product_autocomplete_name' => 'products#autocomplete_name'
  
  get 'product_table' => 'products#table'
  get 'resource_table' => 'resources#table'
  get 'resource_product_table' => 'resources#product_table'
  get 'recipe_table' => 'recipes#table'
  get 'blog_table' => 'blogs#table'
  
  get 'product_graph' => 'products#graph'
  get 'product_graph_json' => 'products#graph_json'
  
  get 'ingredient_json' => 'ingredients#json'
  get 'recipe_color_json' => 'recipes#get_color'
  
  patch 'sources' => 'sources#duplicate'
  patch 'recipe_update_all' => 'recipes#update_all', as: :recipes_update_all
  
  get 'products/:id/merge' => 'products#merge', as: :merge_product
  get 'blogs/:id/publish' => 'blogs#publish', as: :publish_blog
  get 'blogs/:id/unpublish' => 'blogs#unpublish', as: :unpublish_blog
  
  get 'recipes_tag/:tag' => 'recipes#tag', as: :recipes_tag
  
  get "/pages/:page" => "pages#show"
  
  get '/sitemap' => 'sitemaps#index'
  
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
