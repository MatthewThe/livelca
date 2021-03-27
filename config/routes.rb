Rails.application.routes.draw do
  resources :blogs
  resources :ingredients
  resources :recipes
  resources :resources
  resources :product_aliases
  root to: 'products#index'
  
  resources :products
  resources :countries
  resources :sources
  #resources :users
  resources :receipts
  resources :purchases
  
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
  get 'recipe_table' => 'recipes#table'
  get 'blog_table' => 'blogs#table'
  
  get 'product_graph' => 'products#graph'
  get 'product_graph_json' => 'products#graph_json'
  
  patch 'sources' => 'sources#duplicate'
  
  get 'products/:id/merge' => 'products#merge', as: :merge_product
  get 'blogs/:id/publish' => 'blogs#publish', as: :publish_blog
  get 'blogs/:id/unpublish' => 'blogs#unpublish', as: :unpublish_blog
  
  get "/pages/:page" => "pages#show"
  
  get '/sitemap' => 'sitemaps#index'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

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
