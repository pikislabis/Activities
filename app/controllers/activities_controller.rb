class ActivitiesController < ApplicationController
 
	require_role "super_user"


	def index
		@user = User.find(session[:user_id])
		if @user.has_role?('admin')
			@activities = Activity.pag(params[:page])
		elsif @user.has_role?('super_user')
			@activities = Activity.pag_sql(params[:page], @user.id)
		end
	end
	

	def new
		@user = User.find(session[:user_id])
		if params[:proj_id].nil?
			@proj = 0
		else
			@proj = params[:proj_id]
		end
		if @user.has_role?('admin')
			@projs = Project.find(:all)
		elsif @user.has_role?('super_user')
			@projs = Project.find(:all, :conditions => {:user_id => @user.id})
			if @projs.length == 1			# Si solo hay un proyecto, se selecciona automaticamente
				@proj = @projs[0].id 		# para añadir la actividad
			end
		end
		@activity = Activity.new
	end

	
	def show
		@user = User.find(session[:user_id])
		if correct_user(@user, params[:id])
			begin
				@activity = Activity.find(params[:id])
			rescue ActiveRecord::RecordNotFound
				flash[:error]="Actividad incorrecta."
				redirect_to (:action => :index)
			end
		else
			flash[:error] = "Actividad incorrecta."
			redirect_to (:action => :index)
		end
	end

	
	def create
		@activity = Activity.new(params[:activity])
	    
	  if @activity.save
    	flash[:notice] = "La actividad #{@activity.id} ha sido creado satisfactoriamente."
      redirect_to(:controller => :projects, :action => :index)
    else
      render :action => "new"
    end
	end


	protected

	# devuelve los id de todas las actividades de los proyectos de los que un usuario es
	# jefe de proyecto

	def admin_activities(user)
		activities_aux = Project.find(:all, 
							:conditions => {:user_id => user.id}).collect{|x| x.activities }

		activities_aux = activities_aux.flatten.collect{|y| y.id }
				
		activities_aux.flatten
	end

	# Indica si un usuario es administrador, o si es jefe de proyecto y la actividad que quiere
	# ver pertenece a uno de sus proyectos.

	def correct_user(user, param)
		((user.has_role?('super_user') and admin_activities(user).include?(param.to_i)) or
			(user.has_role?('admin')))
	end

end
