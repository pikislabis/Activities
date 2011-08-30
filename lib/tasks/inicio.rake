namespace :activities do
  desc "Tareas iniciales."
  task :iniciar => :environment do
    rol_admin = Role.create(:name => 'admin')
    rol_super_user = Role.create(:name => 'super_user')
    rol_admin.save and rol_super_user.save

    user = User.create(	:long_name => 'Administrador',
                        :name => 'admin',
                        :password => 'administrador',
                        :password_confirmation => 'administrador',
                        :email => 'admin@agaex.com',
                        :state => 'active')
    user.save

    user.roles << rol_admin
    
    project = Project.create(:name => 'Prueba', :description => 'Proyecto de prueba',
                             :billable => 0, :user_id => user.id)
    project.save

    user.projects << project

    tasks_val = TasksValidated.create(:user_id => user.id, :week => Time.now.strftime("%W").to_i,
                                      :year => Time.now.strftime("%Y").to_i, :validated => "0")
    tasks_val.save
  end
end