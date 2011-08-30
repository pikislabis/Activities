# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # AuthenticatedSystem must be included for RoleRequirement, and is provided by installing acts_as_authenticates and running 'script/generate authenticated account user'.
  include AuthenticatedSystem
  # You can move this into a different controller, if you wish.  This module gives you the require_role helpers, and others.
  include RoleRequirementSystem

  require 'aasm'
  
	layout "layout"
	
	before_filter :authorize, :except => [:login, :activate]

	#session :session_key => '_activities_session_id'
	
 	helper :all # include all helpers, all the time

	# See ActionController::RequestForgeryProtection for details
	# Uncomment the :secret if you're not using the cookie session store
	
	rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
	
	protected	
	
		# Verifica si hay usuario logueado en el sistema
		# Si no es así, redirige a la pantalla principal

		def authorize
			unless User.find_by_id(request.session[:user_id])
				RAILS_DEFAULT_LOGGER.info("\n\n user_id -> #{session[:user_id]} \n\n")
				uri = request.request_uri
				reset_session
				if(User.count == 0)
					flash[:notice] = "Por favor, introduzca el primer usuario en el sistema"
				else
					flash[:notice] = "Por favor, identifiquese"
				end
				redirect_to(:controller => :users, :action => :login, :uri_aux => uri.to_s)
			end
		end
	
		
		# Cuando se captura un error de Record Not Found, se lanza la pagina 404.html
		
		def record_not_found
    		render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => 404
    end

    # Devuelve un array con los dias (numero) de la semana a la que pertenece la fecha que se pasa
	  # por parametro
	  def days_of_week(date)

      days = Array.new

		  for x in (0..4)
			  days << date.monday + x
		  end
		  days
    end

    # Funcion que resume un texto cuando la longitud es mayor que length, y le añade truncate_string
	  # al final
	  def truncate(text, length, truncate_string)
  	  l = length - truncate_string.size
      text.length > length ? text[0...l] + truncate_string : text
	  end
		
end
