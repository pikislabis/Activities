class TasksValidated < ActiveRecord::Base
	belongs_to :user

	def self.find_first(user)
		first_task = TasksValidated.find(:first, :conditions => {:user_id => user.id}, :order => 'week, year ASC' )

    first_week_day = (Date.civil(Time.current.year, 1, 1).cweek == 0 ? Date.civil(Time.current.year, 1, 1).monday + 7 : Date.civil(Time.current.year, 1, 1).monday)

    first_task.nil? ? first_week_day : first_week_day + (first_task.week - 1) * 7

	end


	def self.all_not_validated(user)

		date = TasksValidated.find_first(user)
		tasks_not_validated = Array.new

    while (date < Date.today.monday) do
  		
  		validated = TasksValidated.find(:first, :conditions => {:user_id => user.id, :week => date.cweek, :year => date.year})

			# Si no esta en la tabla o no esta validada, la incluimos
  		if (validated.nil? or (validated.validated == 0))
  			tasks_not_validated << date
  		end
  		
			date += 7

    end

		tasks_not_validated

  end
end
