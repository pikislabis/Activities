class IncidenceMailer < ActionMailer::Base
  def create(incidence)
    setup_email(incidence.user_id)
    @subject << 'Alta de incidencia'
    @body[:url] = "#{APP_CONFIG[:site_url]}/incidences/#{incidence.id}"
		@body[:text] = incidence.description
  end

	def close(incidence)
		setup_email(incidence.user_id)
		@subject << 'Incidencia solucionada'
		@body[:url] = "#{APP_CONFIG[:site_url]}/incidences/#{incidence.id}"
		@body[:incidence] = Incidence.find(incidence.id)
	end

	def receive(email)
		incidence = Incidence.new
		incidence.user_id = User.find(:first, :conditions => {:email_corp => email.from[0]}).id
		incidence.origin = 1
		incidence.state = "creada"
		incidence.priority = "media"
		incidence.type_inc = "seguridad"
		incidence.title = email.subject

		if email.multipart?
			logger.debug "Paso1"
			email.parts.each do |part|
				header = part.content_type.to_s
				logger.debug "Esto es #{header}"
				if header.include? "multipart/alternative"
					logger.debug "Paso2 #{header}"
					part.parts.each do |part2|
						header2 = part2.content_type.to_s
						if (header2.include? "text/plain" and !part2.disposition.include? "attachment")
							logger.debug "Paso3 #{header2}"
							part2.set_disposition("inline")
							incidence.description = part2.body
							logger.debug "Hecho!!!"
							break
						end
					end
				elsif (header.include? "text/plain" and !part.disposition.include? "attachment")
					logger.debug "Paso2 #{header}"
					part.set_disposition("inline")
					incidence.description = part.body
					logger.debug "Hecho!!!"
					break
				end
			end
		else
			incidence.description = email.body
		end

		if incidence.save
			record = Record.new
			record.user_id = incidence.user_id
			record.text1 = "Incidencia creada."
			record.text2 = nil
			record.incidence_id = incidence.id
			record.save
			if email.has_attachments?
  			email.attachments.each do |attach|
    			record.attachment.create(:name => attach)
  			end
			end
		end
	end

  protected
  
  def setup_email(user_id)
    @recipients = "#{User.find(user_id).email_corp}"
    @from = "#{APP_CONFIG[:admin_email]}"
    @subject = "Agaex. "
    @sent_on = Time.now
    @body[:user] = User.find(user_id)
		@content_type = "text/html"
  end
end
