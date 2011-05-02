class UsersController < ApplicationController
		
	skip_before_filter :authorize, :only => [:login, :activate]
	before_filter :values
	
	require_role "super_user", :for_all_except =>
  											[:index, :view_spendings, :edit, :edit_tasks, :login, :logout, 
													:modify_table_tasks, :modify_view_tasks, :create_tasks, 
													:admin_sec, :activate, :modify_alert, :edit_alert, :new_alert,
													:save_alert, :delete_alert,:view_alerts, :pdf_spendings, 
													:pdf_tasks, :validated, :view_tasks, :modify_spending, :delete_all_tasks,
													:save_spending]
													
	require_role "admin", :only => [:new, :destroy, :permissions, :permissions_jp]
	
	protect_from_forgery :only => [:update, :delete, :create]
	
	require 'pdf/writer'
	require 'pdf/simpletable' #requerido por pdf/writer
	require 'iconv'							#convierte texto de una codificacion a otra.
	require 'related_select_form_helper'	#crear select anidados.

	# Muestra las semanas pendientes de validacion que tiene el usuario

	def index    	
    @user = User.find(session[:user_id])

		# Array para almacenar las semanas no validadas
		@tasks_not_validated = TasksValidated.all_not_validated(@user)
	end
    
    
	def show
  	@user = User.find(session[:user_id])
  	begin
    	@current_user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
			flash[:error] = "Usuario incorrecto"
			redirect_to :action => :index
			return
		end
		if !User.belong_to_own_project(@user, @current_user)
			flash[:error] = "No tiene permisos para esta accion."
			redirect_to :action => :index
		end
	end
	

	def edit
		@user = User.find(params[:id])
		@current_user = User.find(session[:user_id])
		# Si la persona logueada es la misma que se quiere editar o es administrador
		if !((@user.id == @current_user.id) or @current_user.has_role?("admin"))
		  flash[:error] = "Acceso denegado."
	    redirect_to(:action => "index")
    end
	end

	# Muestra los proyectos a los que está adscrito un usuario
	def edit_proj
		@user = User.find(params[:id])
		@user_admin = User.find(session[:user_id])
		if !User.belong_to_own_project(@user, @current_user)
			flash[:error] = "No tiene permisos para esta accion."
			redirect_to :action => :index
		else
			@projects = UserProject.find(:all,
								:conditions => {:user_id => @user.id}).collect{|x| Project.find(x.project_id)}
		end
	end

	# Editar las semanas de las hojas de actividades
	def edit_tasks
		@user = User.find(session[:user_id])
		# Proyectos a los que esta adscrito el usuario
		@projects = @user.projects_belong

		# Si viene a traves de un enlace de la pagina principal index
		if (params[:id1])
			session[:current_date] = params[:id1].to_date
		else
			session[:current_date] = Date.today
		end

		@current_date = session[:current_date]

		# Dias (numero) de la semana
		@days = days_of_week(@current_date.to_date)
		@project = Project.find(session[:current_project_id])
		session[:current_activity_id] = @project.activities.first.id
		
		# Actividades de la semana con tareas
		@activities = Activity.this_week_with_tasks(@user, @current_date)
		
		# Vemos si la semana está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => @user.id,
													:week => @current_date.to_date.strftime("%W"),
													:year => @current_date.to_date.year})
	end
	

	def view_tasks
		# Usuario logueado
		@current_user = User.find(session[:user_id])
		# Usuario del que se quieren ver las tareas
		@user = User.find(params[:id])
		# Devuelve los proyectos del que el user_view es jefe de proyecto y el user esta adscrito
		@interseccion = intersection_proj(@current_user, @user)

		# Si el user_view es el mismo que el user o es administrador o es jefe de proyecto de algun
		# proyecto en el cual esta adscrito el user
		if User.allow_to_view(@current_user, @user)
			session[:user_view] = @user
			session[:t_view] = "Semana"
			
			# Si el user_admin es el mismo que el user o es administrador, mostrará todos los proyectos
			# Si no es asi, solo mostrara los proyectos de los que es jefe de proyecto
			@projects = Array.new
			if ((@current_user.id == @user.id) or (@current_user.has_role?('admin')))
				@projects = @user.user_projects.collect {|x| Project.find(x.project_id)}
			else
				@projects = @interseccion.collect {|x| Project.find(x)}
			end

			# Para que aparezca en el select y poder visualizar todos los proyectos
			project = Project.new(:name => "Todos")
			project.id = 0
			@projects << project
			
			session[:current_date] = Date.today
			@current_date = session[:current_date]
			@days = days_of_week(@current_date.to_date)
			@project = @projects[0]
			session[:current_project_view_id] = @project.id
			@typeView = [['Semanal', 'Semanal'], ['Mensual', 'Mensual']]			
			session[:t_view] = "Semanal"
		else
			flash[:error] = "Acceso denegado."
		  redirect_to(:action => "index")
		end
	end
	
	# Visualizacion de las hojas de gastos
	def view_spendings
		@user_admin = User.find(session[:user_id])
		@user = User.find(params[:id])
		
		if User.allow_to_view(@user_admin, @user)
			if !params[:date].blank?
				session[:current_date] = params[:date].to_date
			else
				session[:current_date] = Date.today
			end
			@current_date = session[:current_date]
		  session[:user_view] = @user.id
		  @current_month = @current_date.to_date.mon
			@current_year = @current_date.to_date.year
			# Primer dia del mes actual
			@first_day = @current_date.to_date.at_beginning_of_month
			# Dias del mes actual
			@days_in_month = Time.days_in_month(@current_month, @current_year)
			# Cogemos el valor del kilometro
			@import = Spending.import
	  else
		  flash[:error] = "Acceso denegado."
		  redirect_to(:action => "index")
    end
	end

	
	def update
		@user = User.find(params[:id])
		if @user.update_attributes(params[:user])
	  	flash[:notice] = "El usuario #{@user.name} ha sido actualizado satisfactoriamente."
	    redirect_to(:action => :index)
	  else
			flash[:error] = "Ha ocurrido un error"
	  	render :action => "edit"
	  end
 	end
	
	# Muestra la lista de todos los usuarios si el usuario logueado es administrador,
	# o de los usuarios que estan adscritos a sus proyectos si es jefe de proyecto
	def list
		@user = User.find(session[:user_id])
		if @user.has_role?('admin')
			@users = User.search(params[:search], params[:page])
		elsif @user.has_role?('super_user')
			@users = User.search2(params[:search], params[:page], @user.id)
		end
	end
  
	
	def login
		session[:current_date] = Date.today
		@current_date = session[:current_date]
		session[:user_id] = nil
		$proj = 0
 
		# Si no hay usuarios en el sistema, crea un usuario

    reset_session
    user = User.authenticate(params[:name], params[:password])

    if user
      session[:user_id] = user.id

      session[:current_project_id] = user.projects.first.id

      uri = session[:original_uri]
      session[:original_uri] = nil
      redirect_to(uri || {:controller => "users", :action => "index" })
      return
    else
      flash[:error] = "Usuario y/o password incorrectos.\n
          <a href = ../forgot_password>¿Olvidó su contraseña?</a>"
    end

		render(:layout => false)
	end

	
	def logout
		session[:user_id] = nil
		session[:current_project_id] = nil
		redirect_to(:action => "login")
	end

	
	def new
    @user = User.new	
	end
	
	def create
	  create_new_user(params)
	end
	
	# Activa un usuario nuevo
	def activate
	  user = User.find_by_activation_code(params[:activation_code]) unless 
																																params[:activation_code].blank?
	  case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Alta completada. Por favor, identifiquese."
      redirect_to(:action => :login)
    when params[:activation_code].blank?
      flash[:error] = "El codigo de activacion no existe. Por favor, siga el enlace de su email."
      redirect_to(:action => :login)
    else
      flash[:error] = "No se encuentra un usuario con ese codigo. Es posible que ya esté activado."
      redirect_to(:action => :login)
    end
	end
	

	def create_new_user(attributes)
	  @user = User.new(attributes[:user])
	  if @user && @user.valid?
			# Registra al usuario en el sistema sin aun activarlo
	    @user.register!
	    @roleUser = RolesUser.new
			# Crea la primera tareas de validacion en el sistema pero sin validar
	    @tasks_validated = TasksValidated.new(:user_id => @user.id, 
																						:week => Date.today.strftime("%W"), 
	      											              :year => Date.today.year,
	      											              :validated => "0")
	    @tasks_validated.save
			# Crea el rol del usuario
	    @roleUser.user = @user
	    @roleUser.role_id = attributes[:super_user]
	    @roleUser.save
	  end
	  
	  if @user.errors.empty?
	    flash[:notice] = "El usuario #{@user.name} ha sido creado satisfactoriamente a la espera de su activacion.\nAsignelo al menos a un proyecto."
	    redirect_to(:action => :edit_proj, :id => @user.id)
	  else
	    flash[:error] = "Hubo un problema al crear la cuenta."
	    render :action => :new
	  end
	end
	
	# Asigna un usuario a un proyecto
	def save_user_proj
		@user = User.find(params[:id])
		@user_proj = UserProject.new(params[:user_project])
		@user_proj.user = @user
	  
		begin
	  	@user_proj.save
	  rescue ActiveRecord::StatementInvalid
		  flash[:error] = "El usuario #{@user.name} no ha podido ser asignado al proyecto. Puede que ya pertenezca al él."
		  redirect_to(:action => "edit_proj", :id => @user.id)
		else  
		  flash[:notice] = "El usuario #{@user.name} ha sido asignado al proyecto."
		  redirect_to(:action => "edit_proj", :id => @user.id )
		end
	end
	
	# Funcion a la que se llama cuando se modifica algun parametro en la vista de la hoja
	# de actividades.
	# La variable hide sirve para controlar cuando mostrar el formulario de introduccion de
	# los datos. Cuando se modifica la fecha, no se muestra. Solo cuando se pulsa el boton
	# añadir que manda el parametro remote_function
	def modify_table_tasks
		@user = User.find(session[:user_id])
		if (params[:current_date].nil? and session[:current_date].nil?)
			session[:current_date] = Date.today
		else
			if !params[:current_date].nil?
				session[:current_date] = params[:current_date]
				@hide = 1
			end
		end
		@current_date = session[:current_date]

		if params[:id] == "remote_function"
			@hide = 0
			if params[:activity].nil?
				if session[:current_activity_id].nil?
					@project = Project.find(session[:current_project_id])
					@activity = @project.activities.first
				else
					@activity = Activity.find(session[:current_activity_id])
					@project = @activity.project
				end
			else
				@activity = Activity.find(params[:activity])
				@project = @activity.project
			end
		else
  		if params[:project].nil?
  			if params[:activity].nil?
    			@project = Project.find(session[:current_project_id])
    			@activity = @project.activities.first
    		else
    			@activity = Activity.find(params[:activity])
    	  	@project = @activity.project
    	  	session[:current_project_id] = @project.id
    	  	session[:current_activity_id] = @activity.id
  			end
  		else
  			@project = Project.find(params[:project])
  			@activity = @project.activities.first
  			session[:current_project_id] = @project.id
  			session[:current_activity_id] = @activity.id
  		end
		end
		
		# Actividades con tareas ejecutadas

		@activities = Activity.get_activities_tasks(@user, @current_date)
		
		@days = days_of_week(@current_date.to_date)
		
		# Mostrará si la semana seleccionada está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => session[:user_id],
															 :week => session[:current_date].to_date.strftime("%W"),
															 :year => session[:current_date].to_date.year})
		render(:layout => false) 		
	end
  	
  	
	def modify_table_spendings
		@user = User.find(session[:user_view])
	  @current_date = params[:current_date]
	  if @current_date.nil?
	    @current_date = Date.today
	  end
	  @current_month = @current_date.to_date.mon
	  @current_year = @current_date.to_date.year
	  @first_day = @current_date.to_date.at_beginning_of_month
	  @days_in_month = Time.days_in_month(@current_month, @current_year)
	  @import = Spending.import
	  
	  render(:layout => false)
	end
  	
  	
	# Para visualizar la hoja de actividades de otros usuarios
	def modify_view_tasks
		
		@user = session[:user_view]
		
		if (params[:current_date].nil? and session[:current_date].nil?)
			session[:current_date] = Date.today
		elsif !params[:current_date].nil?
				session[:current_date] = params[:current_date]
		end

		@current_date = session[:current_date]
  	
		if ((params[:proj].nil?) and (session[:current_project_view_id] != '0'))
  		@project = Project.find(session[:current_project_view_id])
		elsif ((params[:proj] == '0') or ((params[:proj].nil?) and 
												(session[:current_project_view_id] == '0')))
  		@project = "Todos"
  	  session[:current_project_view_id] = '0'
  	  
			@activities = Activity.get_activities_tasks(@user, @current_date)

			@days = days_of_week(@current_date.to_date)

			@validated = TasksValidated.find(:first, :conditions => {   :user_id => @user,
															 		:week => @current_date.to_date.strftime("%W"),
															 		:year => @current_date.to_date.year})
  	      
		else
  		@project = Project.find(params[:proj])
  	  session[:current_project_view_id] = @project.id
		end
		
		if !params[:type_view].nil?
			session[:t_view] = params[:type_view]
		end
		
		@current_month = @current_date.to_date.mon - 1
		@current_year = @current_date.to_date.year
		@days = days_of_week(@current_date.to_date)
			
		render(:layout => false)		
	end

	
	def modify_spending
	  @user = User.find(params[:id])
	  @date = params[:date].to_date
	  @spending = Spending.new( :user_id => @user.id,
	                            :date => @date)
	end
  	
	# Crea un nuevo gasto o modifica uno existente
  def save_spending
		@date = params[:spending][:date].to_date
		@spending = Spending.find(:first, :conditions => {:date => @date, 
																											:user_id => params[:spending][:user_id]})
		if @spending.blank?
			@spending = Spending.new(params[:spending])
			if @spending.save
				flash[:notice] = "Gasto almacenado."
			  redirect_to(:action => :view_spendings, :id => params[:spending][:user_id],
																:date => @date)
			else
			  flash[:error] = "Ha ocurrido un error y el gasto no ha podido ser almacenado."
			  	redirect_to(:action => :view_spendings, :id => params[:spending][:user_id],
																	:date => @date)
			end
		else
		  if @spending.update_attributes(params[:spending])
		  	flash[:notice] = "Gasto actualizado."
			  redirect_to(:action => :view_spendings, :id => params[:spending][:user_id],
																:date => @date)
		  else
				flash[:error] = "Ha ocurrido un error y el gasto no ha podido ser actualizado."
		  	render :action => "modify_spending"
			end
		end
	end


  # Añade una nueva tarea	
 	def create_tasks
  	@current_date = session[:current_date]
  	@user = session[:user_id]
		for y in (0..4)
			# Indentifica los diferentes parametros, uno para cada dia de la semana
			@params = "hours_tag_" + y.to_s
			if ((!params[@params].nil?) and (params[@params].to_i != 0))
				@new_task = Task.find(:first, :conditions => {:user_id => @user,	
															:activity_id => session[:current_act],
															:date =>  session[:current_date].to_date.monday + y})
				# Si la tarea no existe, crea una nueva
				if (@new_task.blank?)								
					@new_task = Task.new(	:user_id => @user,
							 				:activity_id => session[:current_act],
							 				:date => @current_date.to_date.monday + y,
							 				:hours => params[@params])	 				
					begin		 				
						@new_task.save
						rescue ActiveRecord::StatementInvalid
							flash[:error] = "No se han podido asignar las tareas."
							redirect_to(:action => "edit_tasks")
							return
	  				end
				# Si existe, la actualiza
				else
					@new_task.update_attributes(:hours => params[@params])
				end
			end
		end
		flash[:notice] = "Las tareas han sido asignadas correctamente."
		redirect_to(:action => "edit_tasks", :id1 => session[:current_date].to_date)
	end
	
	# Modificacion de los administradores y los jefes de proyectos
	def mod_all
		if (params[:id] == "1")
		  @roluser = RolesUser.new(:role_id => "1", :user_id => params[:role][:user_id])
		else
		  @roluser = RolesUser.new(:role_id => "2", :user_id => params[:role][:user_id])
		end
		begin
			@roluser.save
			# Si introducimos un usuario como jefe de proyecto, eliminamos su rol referente a
			# usuario normal
			if (params[:id] == "2")
      	@rol_norm_user = RolesUser.find(:first, 
														:conditions => {:user_id => params[:role][:user_id], :role_id => 3})
      	if !@rol_norm_user.nil?
        	@rol_norm_user.destroy
      	end
    	end
			flash[:notice] = "La modificacion ha sido realizada correctamente."
		rescue Exception => e
			flash[:error] = e.message
		end
		
		if (params[:id] == "1")
    	redirect_to(:action => :permissions)
    else
    	redirect_to(:action => :permissions_jp)
    end  
	end
	
	
	# Eliminacion de una semana de tareas
	def delete_tasks
		for x in (0..4)
			@task = Task.find(:first, :conditions => {:user_id => session[:user_id], 
																								:activity_id => params[:id], 
							  							  								:date => session[:current_date].to_date.monday + x})
			if !@task.nil?
				begin
					@task.destroy
				rescue Exception => e
					flash[:error] = "Error. "+e.message
				end
			end
		end
		redirect_to(:action => "edit_tasks", :id1 => session[:current_date].to_date)						
	end
	

	# Para eliminar varias lineas de tareas a la vez
	def delete_all_tasks
		if params[:tasks].nil?
			flash[:error] = "No ha seleccionado ninguna linea."
		else
			for x in params[:tasks]
				if !x.nil?
					for y in (0..4)
						@task = Task.find(:first, :conditions => {:user_id => session[:user_id], 
																								:activity_id => x, 
																  							:date => session[:current_date].to_date.monday + y})
						begin
							@task.destroy
						rescue Exception => e
							flash[:error] = "Error. "+e.message
						end
					end
				end
			end
		end
		redirect_to(:action => "edit_tasks", :id1 => session[:current_date])
	end
	

	def delete_alert
		@alert = Alert.find(params[:id])
		if @alert.user_id == session[:user_id]
			begin
				@alert.destroy
			rescue Exception => e
				flash[:error] = "Error. "+e.message
			end
		else
			flash[:error] = "Error. No puede borrar esta alerta."
		end
		redirect_to(:controller => 'users', :action => 'view_alerts', :id => session[:user_id])
	end

	# Eliminacion de los roles de los usuarios
	def delete_role
	  @roluser = RolesUser.find(:first, :conditions => {:user_id => params[:id], 
																											:role_id => params[:id2]})
	  @roluser.destroy
	  
	  redirect_to(:controller => 'users', :action => 'permissions')
	end

	# Eliminacion de los usuarios
	def destroy
		@user = User.find(params[:id])
		begin
	    	@user.destroy
	    	flash[:notice] ="El usuario #{@user.name} ha sido eliminado"
	    rescue Exception => e
	    	flash[:error] = e.message
		  end
	    redirect_to(:controller => 'users', :action => 'list')
	end
	
  # Desvinculacion de un usuario de un proyecto
	def delete_proj
		@user = User.find(params[:id1])
		@project = Project.find(params[:id2])
		@user_proj = UserProject.find(:first, :conditions => {:project_id => params[:id2],
																													:user_id => params[:id1]})
		begin
			@user_proj.destroy
			flash[:notice] = "El usuario #{@user.id} ha sido desvinculado del proyecto #{@project.id}"
		rescue Exception => e
			flash[:error] = e.message
		end
		redirect_to(:action => :edit_proj, :id => @user.id)	
	end
	
	
	# Validacion de una semana de actividades
	def validated
		@validated = TasksValidated.find(:first, :conditions => {:user_id => session[:user_id], 
																 :week => session[:current_date].to_date.strftime("%W"),
																 :year => session[:current_date].to_date.year})
		# Si no existe la validacion, se crea
		if @validated.nil?
			@validated = TasksValidated.new(:user_id => session[:user_id], 
										   :week => session[:current_date].to_date.strftime("%W"),
										   :year => session[:current_date].to_date.year,
										   :validated => "1")
			begin
				@validated.save
				flash[:notice] = "Se ha validado la semana de forma correcta."
			rescue Exception => e
				flash[:error] = "Ha ocurrido un error. "+e.message
			end
		# Si existe, se valida
		else
			begin
				@validated.update_attributes(:validated => "1")
				flash[:notice] = "Se ha validado la semana de forma correcta."
			rescue Exception => e
				flash[:error] = "Ha ocurrido un error. "+e.message
			end
		end
		redirect_to(:action => :edit_tasks, :id1 => session[:current_date])
	end

	
	def view_alerts
		@user = User.find(session[:user_id])
		@alerts = Alert.paginate_by_user_id @user.id, :per_page => 6, :page => params[:page],
																	 								:order => 'date ASC'
	end
	

	def new_alert 
		@alert = Alert.new
	end
	

	def save_alert
		@alert = Alert.new(params[:alert])
		@alert.user_id = session[:user_id]
		begin
	    	@alert.save
	        flash[:notice] = "La alerta ha sido almacenada con exito."
	    rescue Exception => e
	    	flash[:error] = "Ha ocurrido un error. "+e.message
		end
   	redirect_to(:action => :view_alerts, :id => session[:user_id])	
	end

	
	def modify_alert
		@alert = Alert.find(params[:id_alert])		
		render(:layout => false)
	end
	

	def edit_alert
		@alert = Alert.find(params[:id])
		begin
			@alert.update_attributes({:text => params[:text],
																:date => params[:date],
																:frequency => params[:frequency]})
			flash[:notice] = "La alerta ha sido modificada con exito."
		rescue Exception => e
			flash[:error] = "Ha ocurrido un error. "+e.message
		end
		redirect_to(:action => :view_alerts, :id => session[:user_id])
	end
	 
	
	# Creacion del pdf de la hoja de gastos
	def pdf_spendings
	    @user = User.find(params[:id])
	    pdf = PDF::Writer.new(:paper => "A4",
	                          :orientation => :landscape)
	    pdf.margins_pt(5)
	    pdf.image("public/images/agaex400.jpg", {:resize => 0.5, :pad => 0})                      
	                                                
	    @current_month = params[:date_month].to_i
	    @current_year = params[:date_year].to_i
	    @days_in_month = Time.days_in_month(@current_month, @current_year)
	    @current_date = DateTime.civil(@current_year, @current_month, 1, 0, 0, 0, 0)
	    
	    PDF::SimpleTable.new do |tab|
	      tab.column_order = ["col1", "col2", "col3"]
	      tab.title = "<b>HOJA MENSUAL DE GASTOS</b>"
	      tab.maximum_width = 650
	      tab.title_font_size = 18
	      tab.font_size = 12 
	      
	      tab.columns["col1"] = PDF::SimpleTable::Column.new("col1"){ |col|
	        col.width = 350
	        col.justification = :center
	      }
	      tab.columns["col2"] = PDF::SimpleTable::Column.new("col2"){ |col|
	        col.width = 150
	        col.justification = :center
	      }
	      tab.columns["col3"] = PDF::SimpleTable::Column.new("col4"){ |col|
	        col.width = 150
	        col.justification = :center
	      }
	      
	      tab.show_lines = :all
	      tab.show_headings = false
	      tab.orientation = :center
	      tab.position = :center
	      tab.shade_color = Color::RGB::Grey90
	      data = []
	      data << { "col1" => "Colaborador: " + @user.long_name,
	                "col2" => "Mes: "+ @current_date.strftime("%B").to_s.capitalize,
	                "col3" => User.pasar_a_iso("Año: ") + @current_year.to_s}
	      tab.data.replace data
	      tab.render_on(pdf)
	    end
	    
	    pdf.text("\n")
	    
	    PDF::SimpleTable.new do |tab|
	      tab.column_order = ["col1", "col2", "col3", "col4", "col5", "col6", "col7", "col8"]
	      tab.font_size = 9
	      tab.width = 650
	      tab.bold_headings = true
	      
	      tab.columns["col1"] = PDF::SimpleTable::Column.new("col1"){ |col|
	        col.justification = :center
	        col.heading = User.pasar_a_iso("Día")
	        col.heading.justification = :center
	      }
	      tab.columns["col2"] = PDF::SimpleTable::Column.new("col2"){ |col|
	        col.justification = :center
	        col.heading = "Lugar de la Actividad"
	        col.heading.justification = :center
	      }
	      tab.columns["col3"] = PDF::SimpleTable::Column.new("col3"){ |col|
	        col.justification = :center
	        col.heading = "Kms"
	        col.heading.justification = :center
	      }
	      tab.columns["col4"] = PDF::SimpleTable::Column.new("col4"){ |col|
	        col.justification = :center
	        col.heading = "Importe"
	        col.heading.justification = :center
	      }
	      tab.columns["col5"] = PDF::SimpleTable::Column.new("col5"){ |col|
	        col.justification = :center
	        col.heading = "Transporte"
	        col.heading.justification = :center
	      }
	      tab.columns["col6"] = PDF::SimpleTable::Column.new("col6"){ |col|
	        col.justification = :center
	        col.heading = "Comidas"
	        col.heading.justification = :center
	      }
	      tab.columns["col7"] = PDF::SimpleTable::Column.new("col7"){ |col|
	        col.justification = :center
	        col.heading = "Gastos repr."
	        col.heading.justification = :center
	      }
	      tab.columns["col8"] = PDF::SimpleTable::Column.new("col8"){ |col|
	        col.justification = :center
	        col.heading = "TOTAL GASTOS"
	        col.heading.justification = :center
	      }
	      
	      tab.show_lines = :all
	      tab.show_headings = true
	      tab.orientation = :center
	      tab.position = :center
	      tab.shade_rows = :none
	      tab.shade_headings = true
	      
	      @total2 = 0
	      @total_kms = 0
	      @total_parking = 0
	      @total_food = 0
	      @total_represent = 0
	      @import = Spending.import
	      data = []
	      for x in 0..@days_in_month - 1
	        @day = @current_date + x
	        if ((@day.wday != 6) and(@day.wday != 7) and (@day.wday != 0))
	          @spend = Spending.find(:first, :conditions =>{:user_id => session[:user_view],
	  														:date => @day.to_date })
	  			if @spend.blank?
	            	data << { "col1" => @day.day}
	            
	        else
		            @total = @spend.parking.to_f + @spend.food.to_f + @spend.represent.to_f + (@spend.kms.to_f * @import.to_f)
		            @total2 += @total.to_f
		            @total_kms += @spend.kms.to_f
		            @total_parking += @spend.parking.to_f
		            @total_food += @spend.food.to_f
		            @total_represent += @spend.represent.to_f
		            
		            
		            data << { "col1" => @day.day,
		                      "col2" => @spend.place,
		                      "col3" => @spend.kms,
		                      "col4" => "%.2f" % (@spend.kms.to_f * @import.to_f),
		                      "col5" => "%.2f" % @spend.parking.to_f,
		                      "col6" => "%.2f" % @spend.food.to_f,
		                      "col7" => "%.2f" % @spend.represent.to_f,
		                      "col8" => "%.2f" % @total.to_f}
		    	end  
	        end
	      end
	      
	      @col4 = "%.2f" % (@total_kms.to_f * @import.to_f)
	      @col5 = "%.2f" % @total_parking.to_f
	      @col6 = "%.2f" % @total_food.to_f
	      @col7 = "%.2f" % @total_represent.to_f
	      @col8 = "%.2f" % @total2.to_f
	      
	      data << {"col1" => "",
	               "col2" => "<b>TOTALES</b>",
	               "col3" => "<b> #{@total_kms} </b>",
	               "col4" => "<b>#{@col4}</b>",
	               "col5" => "<b>#{@col5}</b>",
	               "col6" => "<b>#{@col6}</b>",
	               "col7" => "<b>#{@col7}</b>",
	               "col8" => "<b>#{@col8}</b>"
                  }
	      
	      tab.data.replace data
	      tab.render_on(pdf)
	      
	    end
	    
	    pdf.text("\n")
	    
	    PDF::SimpleTable.new do |tab|
	      tab.column_order = ["col1"]
	      tab.columns["col1"] = PDF::SimpleTable::Column.new("col1"){ |col|
	        col.justification = :left
	      }
	      tab.show_lines = :all
	      tab.show_headings = false
	      tab.orientation = -325
	      tab.position = :right
	      tab.shade_color = Color::RGB::White
	      
	      data=[]
	      data << {"col1" => User.pasar_a_iso("Vº Bº de Direccion\n\n\n\nFecha:\nFdo:_____________________________________")}
	      
	      tab.data.replace data
	      tab.render_on(pdf)
		end
	    
	    send_data pdf.render, :filename => "#{@user.name}_#{@current_month}_#{@current_year}.pdf", :type => "application/pdf"
	end
	

	# Creacion del pdf de la hoja de actividades	
	def pdf_tasks
	  	@user = User.find(params[:id])
	  	@date = params[:date].to_date
	  	
	  	@all_tasks = Array.new
		@activities_aux = Array.new
		for x in (0..4)
		  @unit_tasks = Task.find(:all, :conditions => {:date => @date.monday + x, :user_id => @user.id})
		  for y in (0..@unit_tasks.length - 1)
		    @activities_aux << @unit_tasks[y].activity_id
		  end
		end
		@activities = @activities_aux.uniq
		
		@validated = TasksValidated.find(:first, :conditions => {:user_id => @user.id,
																 :week => @date.strftime("%W"),
																 :year => @date.year})
		
		pdf = PDF::Writer.new(	:paper => "A4",
		                    	:orientation => :landscape)
		pdf.margins_pt(5)                    	
		pdf.image("public/images/agaex400.jpg", {:resize => 0.5, :pad => 0})
		
		PDF::SimpleTable.new do |tab|
			tab.column_order = ["col1", "col2", "col3"]
		    tab.title = "<b>HOJA DE ACTIVIDAD SEMANAL</b>"
		    tab.title_font_size = 20
		    tab.font_size = 14
			
		    tab.columns["col1"] = PDF::SimpleTable::Column.new("col1"){ |col|
		    	col.width = 350
		        col.justification = :center
		    }
		    tab.columns["col2"] = PDF::SimpleTable::Column.new("col2"){ |col|
		        col.width = 150
		        col.justification = :center
		    }
		    tab.columns["col3"] = PDF::SimpleTable::Column.new("col4"){ |col|
		        col.width = 150
		        col.justification = :center
		    }
			tab.show_lines = :all
		    tab.show_headings = false
	  		tab.orientation = :center
	      	tab.position = :center
	      	tab.shade_color = Color::RGB::Grey90
     		data = []
		    data << { 	"col1" => "Colaborador: " + @user.long_name,
		            	"col2" => "Inicio: "+ @date.strftime("%d/%m/%y"),
		                "col3" => "Fin: "+ (@date + 4).strftime("%d/%m/%y")}
		    tab.data.replace data
		    tab.render_on(pdf)
		end
		
		pdf.text("\n")
		
		PDF::SimpleTable.new do |tab|
			tab.column_order = ["col1", "col2","col3","col4","col5","col6","col7","col8","col9"]
			tab.bold_headings = true
			 
	      	tab.columns["col1"] = PDF::SimpleTable::Column.new("col1"){ |col|
	        	col.justification = :center
	    	    col.heading = "Proyecto"
	    	    col.heading.justification = :center
	    	    col.width = 90
	      	}
			tab.columns["col2"] = PDF::SimpleTable::Column.new("col2"){ |col|
	        	col.justification = :center
	        	col.heading = "Actividad"
	        	col.heading.justification = :center
	        	col.width = 90
	      	}
	      	tab.columns["col3"] = PDF::SimpleTable::Column.new("col3"){ |col|
	        	col.justification = :left
	        	col.heading = "Descripcion de la Actividad"
	        	col.heading.justification = :center
	        	col.width = 190
	      	}
	      	tab.columns["col4"] = PDF::SimpleTable::Column.new("col4"){ |col|
	        	col.justification = :center
	        	col.heading = "Lun"
	        	col.heading.justification = :center
	        	col.width = 40
	      	}
	      	tab.columns["col5"] = PDF::SimpleTable::Column.new("col5"){ |col|
	        	col.justification = :center
	        	col.heading = "Mar"
	        	col.heading.justification = :center
	        	col.width = 40
	      	}
	      	tab.columns["col6"] = PDF::SimpleTable::Column.new("col6"){ |col|
	        	col.justification = :center
	        	col.heading = "Mie"
	        	col.heading.justification = :center
	        	col.width = 40
	      	}
	      	tab.columns["col7"] = PDF::SimpleTable::Column.new("col7"){ |col|
	        	col.justification = :center
	        	col.heading = "Jue"
	        	col.heading.justification = :center
	        	col.width = 40
	      	}
	      	tab.columns["col8"] = PDF::SimpleTable::Column.new("col8"){ |col|
	        	col.justification = :center
	        	col.heading = "Vie"
	        	col.heading.justification = :center
	        	col.width = 40
	      	}
	      	tab.columns["col9"] = PDF::SimpleTable::Column.new("col9"){ |col|
	        	col.justification = :center
	        	col.heading = "Total"
	        	col.heading.justification = :center
	        	col.width = 40
	      	}
	      
		    tab.show_lines = :all
		    tab.show_headings = true
	  		tab.orientation = :center
		    tab.position = :center
		    tab.shade_rows = :none
	     	tab.shade_headings = true
		    
		    data = []
		    @totals = [0,0,0,0,0]
		    for x in (0..@activities.length - 1)
		    	@week = Array.new
		    	@unit_activity = Activity.find(@activities[x].to_i)
		    	@project = Project.find(@unit_activity.project_id).name
		    	@total_w = 0
		    	for z in (0..4)
		    		@task = Task.find(:first, :conditions => {:user_id => @user.id,	
										:activity_id => @unit_activity.id,
										:date =>  session[:current_date].to_date.monday + z})
					if !@task.nil?
						@week[z] = @task.hours
						@totals[z] += @task.hours
					end
					if !@week[z].nil?
						@total_w += @week[z]
					end 
		    	end
		    	
		    	data << {  	"col1" => @project,
		    				"col2" => @unit_activity.name,
		    				"col3" => truncate(@unit_activity.description, 40, "..."),
		    				"col4" => @week[0],
		    				"col5" => @week[1],
		    				"col6" => @week[2],
		    				"col7" => @week[3],
		    				"col8" => @week[4],
		    				"col9" => @total_w
	    				}
		    end
		    
		    @lines = @activities.length
		    
		    if @lines < 18
		    	for y in (@lines - 1..18)
		    		data << {"col1" => " "}
		    	end
		    end
		    
		    tab.data.replace data
		    tab.render_on(pdf)
		    
		    tab.columns["col3"].justification = :right
		    tab.show_lines = :all
		    tab.show_headings = false
		    
		    data = []

        @totals.each {|t| @total_m.nil? ? @total_m = t : @total_m += t}

		    data << { 	"col1" => "",
		    			"col2" => "",
		    			"col3" => "<b>TOTAL: </b>",
		    			"col4" => "<b>#{@totals[0]}</b>",
		    			"col5" => "<b>#{@totals[1]}</b>",
		    			"col6" => "<b>#{@totals[2]}</b>",
		    			"col7" => "<b>#{@totals[3]}</b>",
		    			"col8" => "<b>#{@totals[4]}</b>",
		    			"col9" => "<b>#{@total_m}</b>"
	    			}
	    			
	    	tab.data.replace data
		    tab.render_on(pdf)
		    
		end
		
		pdf.text("\n")
		
		PDF::SimpleTable.new do |tab|
	      tab.column_order = ["col1"]
	      tab.columns["col1"] = PDF::SimpleTable::Column.new("col1"){ |col|
	        col.justification = :left
	      }
	      tab.show_lines = :all
	      tab.show_headings = false
	      tab.orientation = -345
	      tab.position = :right
	      tab.shade_color = Color::RGB::White
	      
	      data=[]
	      data << {"col1" => User.pasar_a_iso("Vº Bº Jefe de Proyecto\n\n\n\nFecha:\nFdo:_____________________________________")}
	      
	      tab.data.replace data
	      tab.render_on(pdf)
		end
	
		send_data pdf.render, :filename => "#{@user.name}_#{@date.strftime("%d/%m/%y")}.pdf", :type => "application/pdf"          	
	                    	
	end
	
	

private
  
  
	def redirect_to_index(msg = nil)
		flash[:notice] = msg if msg
    redirect_to :action => :edit_tasks
  end
  

	# Funcion que resume un texto cuando la longitud es mayor que length, y le añade truncate_string
	# al final
	def truncate(text, length, truncate_string)
  	l = length - truncate_string.size
    text.length > length ? text[0...l] + truncate_string : text
	end

	# Devuelve un array con los dias (numero) de la semana a la que pertenece la fecha que se pasa
	# por parametro 
	def days_of_week(date)
  	days = Array.new

		for x in (0..4)
			@date_aux = date.monday.day + x
			if(@date_aux > Time.days_in_month(date.monday.mon,date.monday.year))
				@date_aux -= Time.days_in_month(date.monday.mon,date.monday.year)
			end
			days << @date_aux
		end	
		days
	end
  	
	# Devuelve los proyectos en los que admin es jefe de proyecto y user está adscrito
	def intersection_proj (admin, user)
		
		aux = admin.projects.collect{|x| x.id}

		aux2 = user.user_projects.collect{|x| x.project_id}

		aux & aux2
	end

	def values
		@freq_type = ["Una vez", "Diaria", "Semanal", "Mensual"]
		@frequencies = [['Una vez', 0], ['Diaria', 1], ['Semanal', 2], ['Mensual', 3]]
	end
end
