class TasksValidated < ActiveRecord::Base
	belongs_to :user

	def self.find_first(user)
		first_task = TasksValidated.find_by_sql("SELECT * FROM `tasks_validateds` 
															WHERE `user_id` = #{user.id} AND 
    	 												`week` <= ALL (SELECT `week` FROM `tasks_validateds` WHERE
    	 												`user_id` = #{user.id} AND 
																`year` <= ALL (SELECT `year` FROM `tasks_validateds` WHERE
																`user_id` = #{user.id}) )").first

    if first_task.nil?
		  first_week = DateTime.civil(Time.current.year,1,1,0,0,0)
    else
      first_week = DateTime.civil(first_task.year,1,1,0,0,0).advance(:days => first_task.week * 7 - 1)
    end
    first_week
	end

	def self.all_not_validated(user)

		first_week = TasksValidated.find_first(user)
		tasks_not_validated = Array.new

		y = 0
    x = 0

    while (y == 0) do
    		
  		date = first_week.to_date + x
  		
  		validated = TasksValidated.find(:first, :conditions => { :user_id => user.id,
  																	:week => date.to_date.strftime("%W"),
  																	:year => date.to_date.year})

			# Si no esta en la tabla o no esta validada, la incluimos
  		if (validated.nil? or (validated.validated == 0))
  			tasks_not_validated << date.to_date
  		end
  		
			# Si ya hemos llegado a la semana actual, terminamos
  		if (Time.now.at_beginning_of_week.to_date - date.to_date) < 1
  			y = 1
  		end
			# Para calcular la semana siguiente
  		x += 7
  	end
		tasks_not_validated
	end
end
