namespace :prueba do
  
	desc "Manda mails de las alertas"
	task :send_mail do
		@alerts = Alert.find(:all)
		for alert in @alerts
			@user = User.find(alert.user_id)
			x = alert.frequency
			case x.to_i
				when 0:
					if (Date.today == alert.date.to_date)
						User.send_mail(@user.email, alert.text)
					end
				when 1:
					User.send_mail(@user.email, alert.text)
				when 2:
					if (Date.today.wday.to_i == alert.date.to_date.wday.to_i)
						User.send_mail(@user.email, alert.text)
					end
				else
					if (Date.today.day.to_i == alert.date.to_date.day.to_i)
						User.send_mail(@user.email, alert.text)
					end		
			end
		end
	end
	
	desc "Modifica la variable de entorno RAILS_ENV='development'."
  task :development do
    ENV['RAILS_ENV'] = RAILS_ENV = 'development'
    Rake::Task[:environment].invoke
  end

  desc "Modifica la variable de entorno RAILS_ENV='production'."
  task :production do
    ENV['RAILS_ENV'] = RAILS_ENV = 'production'
    Rake::Task[:environment].invoke
  end

end
