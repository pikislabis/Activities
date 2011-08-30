class PasswordMailer < ActionMailer::Base
  def forgot_password(password)
    setup_email(password.user)
    @subject << 'Ha solicitado cambiar su password'
    @body[:url] = "#{APP_CONFIG[:site_url]}/change_password/#{password.reset_code}"
  end

  def reset_password(user)
    setup_email(user)
    @subject << 'Su password ha sido cambiado.'
  end

  protected
  
  def setup_email(user)
    @recipients = "#{user.email}"
    @from = "#{APP_CONFIG[:admin_email]}"
    @subject = "Agaex. "
    @sent_on = Time.now
    @body[:user] = user
		@content_type = "text/html"
  end
end
