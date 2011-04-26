# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	# Coloca el foco de texto en el id que se le pase por parametro
	def set_focus_to_id(id)
  	javascript_tag("$('#{id}').focus()");
  end
  
	# Oculta un div si se da la condicion pasada por parametro
	def hidden_div_if(condition, attributes = {}, &block)
		if condition
			attributes["style" ] = "display: none"
		end
		content_tag("div" , attributes, &block)
	end
	
	# Indica la posicion el elemento el el array
	def at_array(elemento, array)
		posicion = 1
		for x in array
			if elemento == x
				break;
			else
				posicion += 1
			end
		end
		posicion
	end

	
	def link_to_file(name, file, *args)
		if file != ?/
			file = "#{file}"
		end
		link_to name, file, *args
	end
	
end
