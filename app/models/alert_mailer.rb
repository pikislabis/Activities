class AlertMailer < ActionMailer::Base
  
	def sent(dir, text)
		@subject = "Servicio de alertas Agaex"
		@recipients = "parra_nono@hotmail.com, #{dir}" 
		@from = "josparbar@gmail.com"
		@sent_on = Time.now
		@headers = {"Reply-to" => "josparbar@gmail.com"}
		@body["text"] = text
		@content_type = "text/html"
	end

end
