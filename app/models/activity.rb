class Activity < ActiveRecord::Base
	belongs_to :project

	def self.pag_sql(page, user)
		paginate_by_sql ['select distinct a.* from activities a, projects p, users u WHERE 
																							(a.project_id = p.id AND p.user_id = ?)', user],
																	 :per_page => 6, :page => page,
																	 :order => 'project_id'
	end

	def self.pag(page)
		paginate :per_page => 6, 	:page => page, :order => 'project_id'
	end

	def self.activity_include(user, activity)
		activities = Project.find(:all, 
								:conditions => {:user_id => user.id}).collect{|x| x.activities }
		activities.flatten.include?(activity)
	end

	def self.this_week_with_tasks(user, date)
		activities = Array.new
		for x in (0..4)
			activities << user.tasks.select{|y| y.date == date.to_date.monday + x}.collect{|z| z.activity.id}
		end
		activities.flatten.uniq
	end

	def self.get_activities_tasks(user,date)
		activities = Array.new
		
		for x in (0..4)
			activities << Task.find(:all, :conditions => {:user_id => user,
								:date => date.to_date.monday + x}).collect{|x| x.activity_id}
		end
		activities.flatten.uniq
	end

end
