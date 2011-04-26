class IncidencesController < ApplicationController

  before_filter :values

	# Mostrará todas las incidencias asociadas a un usuario o todas las incidencias
	# del sistema si el usuario es administrador.

  def index
		@user = User.find(session[:user_id])
		@class = modifyClass(params[:id])
		@incidences = Incidence.paginate_user_state(@user, params[:id], params[:page])
  end


  def show
    @incidence = Incidence.find(params[:id])
		@user = User.find(session[:user_id])
		@users = User.find(:all).select{ |u| !u.has_role?('admin') }
		if wrong_user(@user, @incidence)
			flash[:error] = "La incidencia no existe o no tiene privilegios para visualizarla."
			redirect_to(:controller => 'incidences', :action => 'index')
		end
		@attachments = Incidence.all_attachment(@incidence)
		@incidence_types = Hash["abierta" => "abrir", 
														"resuelta" => "resolver", "reasignada" => "reasignar"]
		
  end


  def new
		@incidence = Incidence.new
  end


  def create
  	@incidence = Incidence.new(params[:incidence])
		@incidence.origin = 0
		@incidence.user_id = session[:user_id]
		@incidence.state = "creada"
		@incidence.priority = "media"

    if @incidence.save
			@record = Record.new
			@record.user_id = User.find(session[:user_id])
			@record.text1 = "Incidencia creada."
			@record.text2 = nil
			@record.incidence_id = @incidence.id
			@record.save
			if !params[:name].blank?
				@attachment = Attachment.new
				@attachment.name = params[:name]
				@attachment.record_id = @record.id
				@attachment.save
			end

    	flash[:notice] = 'La incidencia ha sido creada.'
    	redirect_to(@incidence)
    else
			flash[:error] = 'Ha habido un error.'
      render :action => "new"
    end
  end


  def edit
    @incidence = Incidence.find(params[:id])
  end

	# Cada vez que se modifica una incidencia, se crea una linea de historial con la modificacion
	# realizada.

  def update
    @incidence = Incidence.find(params[:id])

    if @incidence.update_attributes(params[:incidence])
			@record = Record.new
			@record.user_id = session[:user_id]
			@record.text1 = "Incidencia modificada."
			@record.incidence_id = @incidence.id
			@record.save
			
    	flash[:notice] = 'La incidencia ha sido actualizada.'
      redirect_to(@incidence)
    else
			flash[:error] = 'Ha habido un error.'
    	render :action => "edit"
    end
  end


  def destroy
    @incidence = Incidence.find(params[:id])		
		@attachments = @incidence.records.collect{|x| x.attachment.id }.flatten
    if @incidence.destroy     
			Attachment.destroy_all(@attachments)  # borra las carpetas vacias que deja los adjuntos
		end

    redirect_to(incidences_url)
  end

	def records
		@incidence = Incidence.find(params[:id])
		@historial = @incidence.records
	end

	# Muestra todas las lineas de historial asociadas a las incidencias del usuario, o todas las
	# lineas de historial del sistema si el usuario es administrador.

	def all_records
		@user = User.find(session[:user_id])
		@historial = Record.paginate_user(@user, params[:page])
	end

	# Se llama cuando se quiere cambiar el estado de una incidencia.

	def to_edited
		@user = User.find(session[:user_id])
		@users = User.find(:all).select{ |u| !u.has_role?('admin') } 

		@incidence = Incidence.find(params[:id])
		estado = @incidence.state

		# Si el usuario no es administrador, solo puede cambiar el estado de la incidencia a abierta.	

		if !@user.has_role?('admin')
			@incidence.state = "abierta"
		else
			@incidence.state = params[:type]
		end

		# Si el parametro esta vacío, no estará asignado a ningun usuario.

		if params[:incidence].nil?
			@incidence.assigned_to = nil
		else
			@incidence.assigned_to = params[:incidence][:assigned_to]
		end

		@record = Incidence.create_record(@user, @incidence, params, estado)
		if !params[:name].blank?
			@attachment = Attachment.new
			@attachment.name = params[:name]
		end

		if !params[:name].blank? and params[:name].size > 3.megabytes
			flash[:error] = 'Archivo demasiado grande. Debe ser menos de 3 MegaBytes.'
			redirect_to(@incidence)
			return
		end
		
		# Comprobamos primero el adjunto para ver si no es mayor del tamaño estipulado

		if @incidence.save and @record.save

			# Asignamos la relacion del adjunto con la linea de historial			
			if !@attachment.nil?
				@attachment.record_id = @record.id
				@attachment.save
			end

			# Si se ha resuelto la incidencia, se envia un email al creador de la incidencia.

			if @incidence.state == "resuelta"
				IncidenceMailer.deliver_close(@incidence)
			end

			flash[:notice] = 'La incidencia ha sido modificada.'
			if @user.has_role?('admin')
				redirect_to(@incidence)
			else
				redirect_to(:action => 'index')
			end
		else
			flash[:error] = 'Ha ocurrido un error.'
			
			if @user.has_role?('admin')
				redirect_to (@incidence)
			else
				redirect_to :action => 'index'
			end

		end
	end

	def include_attachment
		@user = User.find(session[:user_id])
		@incidence = Incidence.find(params[:id])
	
		if wrong_user(@user, @incidence)
			flash[:error] = 'No tiene privilegios para realizar esta accion'
			redirect_to(:action => 'index')
			return
		end

		@record = Record.new
		@record.incidence = @incidence
		@record.user = @user
		@record.text1 = "Archivo adjuntado"
		@record.text2 = params[:comment]

		if !params[:name].blank?
			@attachment = Attachment.new
			@attachment.name = params[:name]
		else
			flash[:error] = "No ha añadido ningun archivo."
			redirect_to (@incidence)
			return
		end

		if @attachment.save and @record.save

			@attachment.update_attribute(:record_id, @record.id)

			flash[:notice] = 'Se ha añadido el archivo.'
			redirect_to(@incidence)
		else
			if params[:name].size > 3.megabytes
				flash[:error] = 'Archivo demasiado grande. Debe ser menos de 3 MegaBytes.'
			else
				flash[:error] = 'Ha ocurrido un error.'
			end
			redirect_to(@incidence)			
		end
		
	end
	

  private

	def wrong_user(user, incidence)
		(!user.has_role?('admin') and (incidence.user_id != user.id) and 
					(incidence.assigned_to != user.id))
	end
	# Sirve para modificar la clase de las etiquetas <li> de la barra act_nav

	def modifyClass (param)
		class_style = Array.new
		if param.nil?
			class_style[4] = "selected2"
		else
			class_style[@type_state.index(param)] = "selected2"
		end
		class_style
	end
	

	def values
		@type_state = ["creada","abierta","resuelta","reasignada"]
		@type_priorities = ["baja", "media", "alta"]
		@type_incidences = ["seguridad", "hardware", "software", "peticion"]
		@type_origin = ["manual", "e-mail"]
	end
end
