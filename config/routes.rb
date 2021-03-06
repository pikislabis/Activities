ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'tasks', :action => 'index'

	map.activate '/activate/:activation_code', :controller => 'users', 
																						 :action => 'activate', :activation_code => nil
  map.forgot_password 'forgot_password', :controller => 'passwords', :action => 'new'
  map.change_password '/change_password/:reset_code', :controller => 'passwords', :action => 'reset'	
	map.login 'login', :controller => 'users', :action => 'login'
	map.delete_alert 'delete_alert/:id', :controller => 'users', :action => 'delete_alert', :id => nil
	map.logout '/logout', :controller => 'users', :action => 'logout'

  map.connect 'tasks/:day/:month/:year', :controller => :tasks, :action => :show
  map.connect 'tasks/:day/:month/:year/delete', :controller => :tasks, :action => :delete
  map.connect 'tasks/:day/:month/:year/validate', :controller => :tasks, :action => :validate
  map.connect 'tasks/:day/:month/:year/pdf', :controller => :tasks, :action => :pdf

  map.connect 'admin/users/:id/projects', :controller => 'admin/users', :action => :edit_proj

  map.resources :tasks
  map.resources :users
	map.resources :projects
	map.resources :activities
	map.resources :passwords
	map.resources :incidences
	map.resource :sessions

  map.admin 'admin', :controller => 'admin/panel'

  map.namespace :admin do |admin|
    admin.resources :users do |u|
      u.resources :projects
    end
    admin.resources :projects do |p|
      p.resources :activities
    end
    admin.resources :users
    admin.resources :activities
  end

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
end
