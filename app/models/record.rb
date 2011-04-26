class Record < ActiveRecord::Base
	belongs_to	:user

	belongs_to	:incidence

	has_many :attachment,
						:dependent => :destroy

	def self.paginate_user(user, page)
		if user.has_role?('admin')
			paginate :per_page => 6, :page => page,
																:order => 'created_at DESC'
		else
			paginate_by_sql ['select distinct r.* from records r, incidences i, users u 
																	WHERE(r.incidence_id = i.id AND i.user_id = ?) OR 
																			 (r.incidence_id = i.id AND i.assigned_to = ?)', 
																												user.id, user.id],
																												:per_page => 6,
																												:page => page,
																												:order => 'created_at DESC'
		end
	end
end
