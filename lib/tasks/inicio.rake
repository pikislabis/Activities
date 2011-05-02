namespace :activities do
  desc "Tareas iniciales."
  task :iniciar => :environment do
    rol_admin = Role.create(:name => 'admin')
    rol_super_user = Role.create(:name => 'super_user')
    rol_admin.save
    rol_super_user.save

    user = User.create(	:name => 'admin',
                        :password => 'administrador',
                        :password_confirmation => 'administrador',
                        :email => 'admin@agaex.com',
                        :email_corp => 'admin@agaex.com',
                        :state => 'active')
    user.save

    roles = RolesUser.create(:role_id => rol_admin.id, :user_id => user.id)
    roles.save

    project = Project.create(:name => 'Prueba', :description => 'Proyecto de prueba',
                             :billable => 0, :user_id => user.id)
    project.save

    user_project = UserProject.create(:project_id => project.id, :user_id => user.id);
    user_project.save

    tasks_val = TasksValidated.create(:user_id => user.id, :week => Time.now.strftime("%W").to_i,
                                      :year => Time.now.strftime("%Y").to_i, :validated => "0")
    tasks_val.save
  end
end