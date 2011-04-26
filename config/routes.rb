ActionController::Routing::Routes.draw do |map|
  
	map.activate '/activate/:activation_code', :controller => 'users', 
																						 :action => 'activate', :activation_code => nil
  map.forgot_password 'forgot_password', :controller => 'passwords', :action => 'new'
  map.change_password '/change_password/:reset_code', :controller => 'passwords', :action => 'reset'	
	map.login 'login', :controller => 'users', :action => 'login'
	map.delete_alert 'delete_alert/:id', :controller => 'users', :action => 'delete_alert', :id => nil
	
	map.purchase 'users/logout', :controller => 'users', :action => 'logout'
	map.purchase 'users/list', :controller => 'users', :action => 'list'
	map.purchase 'users/edit_tasks', :controller => 'users', :action => 'edit_tasks'
	map.purchase 'users/:id/view_tasks', :controller => 'users', :action => 'view_tasks'
	map.purchase 'users/create_tasks', :controller => 'users', :action => 'create_tasks'
	map.purchase 'users/:id/edit_proj/', :controller => 'users', :action => 'edit_proj'
	map.purchase 'users/:id/view_spendings', :controller => 'users', :action => 'view_spendings'
	map.purchase 'users/pdf', :controller => 'users', :action => 'pdf'
	
	map.purchase 'users/remind', :controller => 'users', :action => 'remind'
	map.purchase 'users/edit_compl/:id', :controller => 'users', :action => 'edit_compl'
	map.purchase 'users/admin_sec', :controller => 'users', :action => 'admin_sec'
	map.purchase 'users/permissions', :controller => 'users', :action => 'permissions'
	map.purchase 'users/permissions_jp', :controller => 'users', :action => 'permissions_jp'
	map.purchase 'users/delete_proj/:id', :controller => 'users', :action => 'delete_proj'
	
	map.purchase 'users/delete_tasks', :controller => 'users', :action => 'delete_tasks'
	map.purchase 'users/validated', :controller => 'users', :action => 'validated'
	map.purchase 'users/new_alert', :controller => 'users', :action => 'new_alert'
	map.purchase 'users/save_alert', :controller => 'users', :action => 'save_alert'
	map.purchase 'users/edit_alert/:id', :controller => 'users', :action => 'edit_alert'
	map.purchase 'activities/new', :controller => 'activities', :action => 'new'
	map.purchase 'incidences/:id/records', :controller => 'incidences', :action => 'records'
	map.purchase 'incidences/all_records', :controller => 'incidences', :action => 'all_records'
	

	map.resources :users
	map.resources :projects
	map.resources :activities
	map.resources :passwords
	map.resources :incidences
	map.resource :session
	
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => 'users', :action => 'index'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/login'
  map.connect ':controller/activate/:activation_code'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
