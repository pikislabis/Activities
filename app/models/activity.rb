class Activity < ActiveRecord::Base
	belongs_to :project
  has_many :tasks,
           :dependent => :destroy

	def self.activity_include(user, activity)
		activities = Project.find(:all, 
								:conditions => {:user_id => user.id}).collect{|x| x.activities }
		activities.flatten.include?(activity)
	end

	def self.this_week_with_tasks(user, date)
		activities = Array.new
		for x in (0..4)
			activities << user.tasks.select{|y| y.date.to_date == date.monday + x}.collect{|z| z.activity}
		end
		activities.flatten.uniq
	end

	def self.get_activities_tasks(user,date)
		activities = Array.new
		
		for x in (0..4)
			activities << Task.find(:all, :conditions => {:user_id => user,
								:date => date.to_date.monday + x}).collect{|x| x.activity}
		end
		activities.flatten.uniq
	end

end
