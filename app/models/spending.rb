class Spending < ActiveRecord::Base
  belongs_to :user
  
  def self.import
    entrada = "public/datos.txt"
    fichero = File.open(entrada)
    
    begin
      
      while linea = fichero.readline
        if linea.include?('kilometro = ')
          tamaño1 = 'kilometro = '.length
          tamaño2 = linea.length
          tamaño3 = ' €'.length
          linea_temp = linea.chars[tamaño1..(tamaño2 - tamaño3 - 1)]
        end
      end
    rescue Exception => e
    fichero.close
    end
    linea_temp
  end

	def self.all_in_month(user, month, year)
		days_in_month = Time.days_in_month(month, year)
		first_day = Date.civil(year, month, 1)
		spendings = Array.new

		for x in 0..days_in_month - 1
			day = first_day + x
			if ((day.wday != 6) and (day.wday != 7) and (day.wday != 0))
				spendings << Spending.find(:first, :conditions =>{:user_id => user.id,
																												:date => day}) 
			end
		end
		spendings 
	end
  
end
