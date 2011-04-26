class Attachment < ActiveRecord::Base
	belongs_to :record
	has_attached_file :name

	validates_attachment_size :name, :less_than => 3.megabytes
end
