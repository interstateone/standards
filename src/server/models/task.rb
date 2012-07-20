class Task
	include DataMapper::Resource

	belongs_to :user
	has n, :checks

	property :id, Serial
	property :title, Text, :required => true
	property :purpose, Text

	timestamps :on

  def created_on
    attribute_get(:created_on).to_time.in_time_zone(self.user.timezone)
  end
end