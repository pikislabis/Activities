class IncidenceObserver < ActiveRecord::Observer

  def after_create(incidence)
    IncidenceMailer.deliver_create(incidence)
  end
end
