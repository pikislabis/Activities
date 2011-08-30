class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Por favor, active su cuenta.'
  
    @body[:url]  = "#{APP_CONFIG[:site_url]}/activate/#{user.activation_code}"
    @body[:pass] = user.password
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Su cuenta ha sido activada.'
    @body[:url]  = "#{APP_CONFIG[:site_url]}"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "Agaex"
      @subject     = "Agaex. "
      @sent_on     = Time.now
      @body[:user] = user
      @content_type = "text/html"
    end
end