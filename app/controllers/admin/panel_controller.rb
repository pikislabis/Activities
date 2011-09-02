class Admin::PanelController < ApplicationController
  
  require_role 'super_user'
  
  def index
  end
end
