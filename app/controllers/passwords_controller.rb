class PasswordsController < ApplicationController

	# Incluimos esta linea, porque de no ser así se crearia un bucle que nos redigiria infinitamente
	# a la pagina incial de login
	
	skip_before_filter :authorize, :all


  def new
    @password = Password.new
    render(:layout => false)
  end


  def create
    @password = Password.new(params[:password])
    @password.user = User.find(:first, :conditions => {:email_corp => @password.email})
    
    if @password.save
			# Se envia un email para el cambio de contraseña
      PasswordMailer.deliver_forgot_password(@password)
      flash[:notice] = "Un enlace para cambiar su contraseña ha sido enviado a #{@password.email}."
      redirect_to :controller => 'users', :action => 'login'
    else
      flash[:error] = "La direccion que ha introducido no pertenece a ningun usuario."
      redirect_to :action => :new
    end
  end


  def reset
    begin
      @user = Password.find(:first, :conditions => ['reset_code = ? and expiration_date > ?', 
      																	params[:reset_code], Time.now]).user
    rescue
      flash[:notice] = 'El link para cambiar la contraseña no es correcto o ha caducado.'
      redirect_to :action => :new
    end
    render(:layout => false)
  end

	# Modifica la contraseña una vez enviado el email.

  def update_after_forgetting
    @user = Password.find_by_reset_code(params[:reset_code]).user
    
    if @user.update_attributes(params[:user])
      flash[:notice] = 'La contraseña ha sido modificada correctamente.'
      redirect_to :controller => 'users', :action => 'login'
    else
      flash[:error] = 'Ha habido un error.'
      redirect_to :action => :reset, :reset_code => params[:reset_code]
    end
  end


  def update
    @password = Password.find(params[:id])

    if @password.update_attributes(params[:password])
      flash[:notice] = 'La contraseña ha sido modificada correctamente.'
      redirect_to(@password)
    else
      render :action => :edit
    end
  end
end
