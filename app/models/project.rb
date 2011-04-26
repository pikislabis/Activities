class Project < ActiveRecord::Base
	has_many  :activities,
	          :dependent => :destroy
	has_many  :user_projects,
	          :dependent => :destroy
	belongs_to :user

	def self.paginate_user(user, page)
		if user.has_role?('admin')
    	paginate :per_page => 6, :page => page,
															 :order => 'name'
    else
    	paginate_by_user_id user.id, :per_page => 6, :page => page,
																	 :order => 'name'
    end
	end

	def self.belong_to_user(user, project)
		user.projects.include?(project)
	end
end
