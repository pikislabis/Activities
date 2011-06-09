class Admin::UsersController < ApplicationController

  require_role 'super_user'

  before_filter :user_logged
  
  def index
		if @user_logged.has_role?('admin') and !params[:search].blank?
			@users = User.long_name_like(params[:search])
    elsif @user_logged.has_role?('admin')
      @users = User.find(:all)
		elsif !params[:search].blank?
			@users = @user_logged.own_projects.map{|p| p.users} & User.long_name_like(params[:search])
    elsif
      @users = @user_logged.own_projects.map{|p| p.users}
    end

    @users = @users.paginate(:page => params[:page], :per_page => 6)

  end

  def show
  	begin
    	@user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
			flash[:error] = "Usuario incorrecto"
			redirect_to :action => :index
			return
		end
		if !@user_logged.own_projects.map{|p| p.users}.include? @user and @user_logged != @user
			flash[:error] = "No tiene permisos para esta acción."
			redirect_to root_path
		end
	end

  def new
    @user = User.new
    @user.roles.build
	end

	def create
	  @user = User.new(params[:user])
    if @user && @user.valid?
			# Registra al usuario en el sistema sin aun activarlo
	    @user.register!
			# Crea la primera tareas de validacion en el sistema pero sin validar
	    @tasks_validated = TasksValidated.new(:user_id => @user.id,
																						:week => Date.today.strftime("%W"),
	      											              :year => Date.today.year,
	      											              :validated => "0")
	    @tasks_validated.save
	  end

	  if @user.errors.empty?
	    flash[:notice] = "El usuario #{@user.name} ha sido creado satisfactoriamente a la espera de su activacion.\nAsignelo al menos a un proyecto."
	    redirect_to(:id => @user.id, :action => :edit_proj)
	  else
	    flash[:error] = "Hubo un problema al crear la cuenta."
	    render :action => :new
	  end
	end

  def permissions
    @users = Role.find_by_name("admin").users
    @users2 = User.find(:all).select {|u| !u.has_role?("admin")}
  end

  def permissions_jp
    @users = Role.find_by_name("super_user").users
    @users2 = User.find(:all).select {|u| !u.has_role2?("super_user")}
  end

  # Modificacion de los administradores y los jefes de proyectos
	def mod_all
    role = Role.find(params[:id])
    user = User.find(params[:role][:user_id])
    user.roles << role

    flash[:notice] = "La modificacion ha sido realizada correctamente."

    redirect_to :back
  end

  # Muestra los proyectos a los que está adscrito un usuario
	def edit_proj
		@user = User.find(params[:id])
		if @user_logged.own_projects.map{|p| p.users}.include? @user
			flash[:error] = "No tiene permisos para esta accion."
			redirect_to :action => :index
		else
			@projects = @user_logged.projects
      @all_projects = Project.find(:all) - @projects
		end
  end

  # Asigna un usuario a un proyecto
	def save_user_proj

    @user = User.find(params[:id])
    @project = Project.find(params[:user][:projects])

    @user.projects << @project

		redirect_to(:action => "edit_proj", :id => @user.id )
	end

  private
  def user_logged
    @user_logged = User.find(session[:user_id])
  end

end
