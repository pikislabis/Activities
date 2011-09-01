class UsersController < ApplicationController

  require 'pdf/writer'
	require 'pdf/simpletable' #requerido por pdf/writer
	require 'iconv'							#convierte texto de una codificacion a otra.
	require 'related_select_form_helper'	#crear select anidados.

	skip_before_filter :authorize, :only => [:login, :activate]
	before_filter :values
	before_filter :find_user, :only => [:show, :edit, :update]
	before_filter :user_logged, :for_all_except => [:login, :logout]

	protect_from_forgery :only => [:update, :delete, :create]

  # TODO Configurar el filtro :user_logged

	# Muestra las semanas pendientes de validacion que tiene el usuario
	def show
  	if !@user_logged.belong_to_own_project(@user)
			flash[:error] = "No tiene permisos para esta accion."
			redirect_to :action => :index
		end
	end

	def edit
		if @user.id != @user_logged.id
		  flash[:error] = "Acceso denegado."
	    redirect_to(:action => "index")
    end
	end

  def update
		if @user.update_attributes(params[:user])
	  	flash[:notice] = "Su perfil ha sido actualizado satisfactoriamente."
	    redirect_to(:action => :index)
	  else
			flash[:error] = "Ha ocurrido un error."
	  	render :action => "edit"
	  end
 	end

  def login
    if !params[:name].nil?
      reset_session
      user = User.authenticate(params[:name], params[:password])

      if user
        session[:user_id] = user.id

        if !user.projects.blank?
          session[:current_project_id] = user.projects.first.id
        end

        uri = session[:original_uri]
        session[:original_uri] = nil
        redirect_to(uri || root_path)
        return
      else
        flash[:error] = "Usuario y/o password incorrectos.\n
            <a href = ../forgot_password>¿Olvidó su contraseña?</a>"
      end
    end

		render(:layout => false)
	end

	def logout
		session[:user_id] = nil
		session[:current_project_id] = nil
		redirect_to(:action => "login")
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

  # TODO El rol de cada usuario se asignará desde el perfil de cada usuario.
	# Modificacion de los administradores y los jefes de proyectos
	def mod_all
    role = Role.find(params[:id])
    user = User.find(params[:role][:user_id])
    user.roles << role

    flash[:notice] = "La modificacion ha sido realizada correctamente."

    redirect_to :back
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
    user = User.find(params[:id])
    user.roles.delete(Role.find(params[:id2]))

	  redirect_to :back
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


private
  
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
	
protected
	
	def user_logged
	  if !session[:user_id].nil?
      @user_logged = User.find(session[:user_id])
    end
  end
  
  def find_user
    @user = User.find(params[:id])
  end
end
