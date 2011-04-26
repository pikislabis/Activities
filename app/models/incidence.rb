class Incidence < ActiveRecord::Base
	belongs_to	:user

	has_many	:records,
						:dependent => :destroy

	def self.paginate_user_state(user, param, page)
		if user.has_role?('admin')
			if param.nil?
	  		paginate :per_page => 6, :page => page, :order => 'created_at DESC'
			else
				paginate_by_state param.to_s, :per_page => 6,
																			:page => page,
																			:order => 'created_at DESC'
			end
		else
			if param.nil?
				paginate :per_page => 6, :page => page,
															:conditions => ["user_id = #{user.id} OR
																												assigned_to = #{user.id}"]
			else
				paginate_by_state param.to_s, :per_page => 6,
															:page => page,
															:conditions => ["user_id = #{user.id} OR
																												assigned_to = #{user.id}"]
			end
		end
	end

	def self.all_attachment(incidence)
		attachments = incidence.records.collect{|x| x.attachment }
		attachments.flatten
	end

	def self.create_record(user, incidence, params, estado)
		record = Record.new
		record.user_id = user
		record.incidence_id = incidence.id
		record.text2 = params[:comment]
		if (incidence.state == 'reasignada')
			user_assigned = User.find(params[:incidence][:assigned_to])
			record.text1 = "Incidencia asignada a "+ user_assigned.name.to_s
		else
			record.text1 = estado.to_s + " => " + incidence.state.to_s
		end
		record
	end
end
