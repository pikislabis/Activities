class TasksController < ApplicationController

  before_filter :user_logged

  require_role "super_user", :for_all_except => [:index, :show, :edit]

  require 'related_select_form_helper'	#crear select anidados.

  def index
    @user = User.find(session[:user_id])

		# Array para almacenar las semanas no validadas
		@tasks_not_validated = TasksValidated.all_not_validated(@user_logged)
	end


  def show
    # Proyectos a los que esta adscrito el usuario
		@projects = @user_logged.projects

    if @projects.blank?
      flash[:error] = "No está asociado a ningún proyecto."
      redirect_to root_path and return false
    end

		if params[:current_date]
      @current_date = params[:current_date].to_date
    else
      @current_date = Date.civil(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    end

		# Dias (numero) de la semana
		@days = days_of_week(@current_date.to_date)
		#@project = Project.find(session[:current_project_id])
		#session[:current_activity_id] = @project.activities.first.id

		# Actividades de la semana con tareas
		@activities = Activity.this_week_with_tasks(@user_logged, @current_date)

		# Vemos si la semana está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => @user_logged.id,
													:week => @current_date.cweek,
													:year => @current_date.year})
  end

  def edit

    if params[:current_date]
      @current_date = params[:current_date].to_date
    else
      @current_date = Date.civil(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    end

		@activity = Activity.find(params[:activity])

    @projects = @user_logged.projects

		# Actividades con tareas ejecutadas

		@activities = Activity.get_activities_tasks(@user_logged, @current_date)

		@days = days_of_week(@current_date.to_date)


    # Mostrará si la semana seleccionada está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => @user_logged.id,
															 :week => @current_date.strftime("%W"),
															 :year => @current_date.year})

    render(:layout => false)

  end

  def info
    @current_date = params[:current_date].to_date
    @days = days_of_week(@current_date.to_date)
    @activities = Activity.get_activities_tasks(@user_logged, @current_date)
    @validated = TasksValidated.find(:first, :conditions => {:user_id => @user_logged,
                                       :week => @current_date.strftime("%W"),
                                       :year => @current_date.year})
    render(:layout => false)
  end

  # Añade una nueva tarea
 	def create_tasks
  	current_date = params[:current_date].to_date

    for y in (0..4)
			# Indentifica los diferentes parametros, uno para cada dia de la semana
			param = "hours_tag_" + y.to_s
			if ((!params[param].nil?) and (params[param].to_i != 0))
				@new_task = Task.find(:first, :conditions => {:user_id => @user_logged.id,
															:activity_id => params[:activity],
															:date =>  current_date.monday + y})
				# Si la tarea no existe, crea una nueva
				if (@new_task.blank?)
					@new_task = Task.new(	:user_id => @user_logged.id,
							 				:activity_id => params[:activity],
							 				:date => current_date.monday + y,
							 				:hours => params[param])
					begin
						@new_task.save
            flash[:notice] = "Las tareas han sido asignadas correctamente."
						rescue ActiveRecord::StatementInvalid
							flash[:error] = "No se han podido asignar las tareas."
							return
	  				end
				# Si existe, la actualiza
				else
					@new_task.update_attributes(:hours => params[param])
          flash[:notice] = "Las tareas han sido asignadas correctamente."
				end
			end
		end
		redirect_to(:action => "show", :day => current_date.day, :month => current_date.month, :year => current_date.year)
   end

  def delete
    current_date = Date.civil(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    for x in (0..4)
			@task = Task.find(:first, :conditions => {:user_id => @user_logged.id,
																								:activity_id => params[:activity],
							  							  								:date => current_date.monday + x})
			if !@task.nil?
				begin
					@task.destroy
				rescue Exception => e
					flash[:error] = "Error. " + e.message
          return
				end
			end
    end
		flash[:notice] = "Se han eliminado las tareas correctamente."
    redirect_to(:action => "show", :day => params[:day], :month => params[:month], :year => params[:year])
  end

  # Validacion de una semana de actividades
	def validate

    current_date = Date.civil(params[:year].to_i, params[:month].to_i, params[:day].to_i)

		@validated = TasksValidated.find(:first, :conditions => {:user_id => @user_logged.id,
																                             :week => current_date.strftime("%W"),
																                             :year => current_date.year})
		# Si no existe la validacion, se crea
		if @validated.nil?
			@validated = TasksValidated.new(:user_id => @user_logged.id,
										                  :week => current_date.strftime("%W"),
																      :year => current_date.year,
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
		redirect_to(:day => current_date.day, :month => current_date.month, :year => current_date.year, :action => :show)
	end

  # Creación del pdf de la semana seleccionada
  def pdf

    current_date = Date.civil(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    create_pdf(@user_logged, current_date)

	end

  private
  def user_logged
    @user_logged = User.find(session[:user_id])
  end

  def create_pdf(user, date)

    @all_tasks = Array.new
    @activities_aux = Array.new
    for x in (0..4)
      @unit_tasks = Task.find(:all, :conditions => {:date => date.monday + x, :user_id => user.id})
      for y in (0..@unit_tasks.length - 1)
        @activities_aux << @unit_tasks[y].activity_id
      end
    end
    @activities = @activities_aux.uniq

    @validated = TasksValidated.find(:first, :conditions => {:user_id => user.id,
                                 :week => date.strftime("%W"),
                                 :year => date.year})

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
        data << { 	"col1" => "Colaborador: " + user.long_name,
                  "col2" => "Inicio: "+ date.monday.strftime("%d/%m/%y"),
                    "col3" => "Fin: "+ (date + 4).strftime("%d/%m/%y")}
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
            @task = Task.find(:first, :conditions => {:user_id => user.id,
                    :activity_id => @unit_activity.id,
                    :date =>  date.monday + z})
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

    send_data pdf.render, :filename => "#{user.name}_#{date.monday.strftime("%d/%m/%y")}.pdf", :type => "application/pdf"

  end

end
