require 'digest/sha1'

class User < ActiveRecord::Base
	
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles
  
  # ---------------------------------------
  # The following code has been generated by role_requirement.
  # You may wish to modify it to suit your need
  has_and_belongs_to_many :roles
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
      @_list ||= self.roles.collect(&:name)
      return true if @_list.include?("admin")
      (@_list.include?(role_in_question.to_s) )
  end
  
  def has_role2?(role_in_question)
      @_list ||= self.roles.collect(&:name)
      return true if @_list.include?(role_in_question.to_s)
  end
  # ---------------------------------------
  
	has_many  :projects
	
	has_many  :user_projects,
	          :dependent => :destroy
				
	has_many  :tasks_validateds
	
	has_many  :tasks,
	          :dependent => :destroy
	          
	has_many  :spendings,
	          :dependent => :destroy

	has_many	:incidences
	
	validates_presence_of :name
	validates_uniqueness_of :name,
							:message => ': El nick solicitado ya esta en uso'
	
	validates_format_of :email_corp, 
	              :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
	              :message => 'debe ser una direccion correcta.'
  
	#attr_accessible :login, :email, :name, :password, :password_confirmation
	
	#validate :password_non_blank

	def self.send_mail(dir_email, texto)
		email = AlertMailer.create_sent(dir_email, texto)
	  	email.set_content_type("text/html")
		AlertMailer.deliver(email)
	end
	
	def self.authenticate(name, password)
  	u = find_in_state :first, :active, :conditions => { :name => name } # need to get the salt
   	u && u.authenticated?(password) ? u : nil
  end

	def self.search(search, page)
		paginate 	:per_page => 5, :page => page,
							:conditions => ['long_name like ?', "%#{search}%"],
							:order => 'long_name'
	end
	
	def self.search2(search, page, user_id)
		if !search.blank?
			paginate_by_sql ['SELECT DISTINCT u.* FROM users u,projects p,user_projects up WHERE 
									(u.id = up.user_id AND 
									up.project_id IN (SELECT p2.id FROM users u2, projects p2 WHERE 
																												(p2.user_id = ?))
									AND u.long_name LIKE ?)', user_id, "%#{search}%"],
																:per_page => 6, :page => page,
																:order => 'long_name'
		else
			paginate_by_sql ['SELECT DISTINCT u.* FROM users u,projects p,user_projects up WHERE 
									(u.id = up.user_id AND 
									up.project_id IN (SELECT p2.id FROM users u2, projects p2 WHERE 
									(p2.user_id = ?)))', user_id],
									:per_page => 6, :page => page,
									:order => 'long_name'
		end
	end
	
	def password_required?
  	new_record? ? (crypted_password.blank? || !password.blank?) : !password.blank?
  end
  	
  def self.pasar_a_iso(texto)
  	c = Iconv.new('ISO-8859-15//IGNORE//TRANSLIT', 'UTF-8')
   	iso = c.iconv(texto)
  end
	
	# Indica si user pertenece a un proyecto de los que el usuario es jefe de proyecto
	def belong_to_own_project(user)
	  users = self.projects.collect {|x| x.user_projects }.flatten
		users.include?(user) or self.has_role?("admin")
	end

	def self.allow_to_view (admin, user)
		(admin == user) or admin.has_role?("admin") or
		 (admin.has_role?("super_user") and admin.belong_to_own_project(user))
	end

  protected
    
  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end
  
end
