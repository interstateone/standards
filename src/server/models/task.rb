class Task
	include DataMapper::Resource

	belongs_to :user
	has n, :checks

	property :id, Serial
	property :title, Text, :required => true
	property :purpose, Text

	timestamps :on

  def created_on
    unless attribute_get(:created_on).nil?
      attribute_get(:created_on).to_time.in_time_zone(self.user.timezone).to_date
    end
  end
end