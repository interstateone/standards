require 'rest_client'
require 'sinatra/base'

class User
  include DataMapper::Resource

  has n, :tasks
  has n, :checks

  property :id, Serial
  property :name, String, :required => true
  property :email, String, :required => true, :unique => true
  property :hashed_password, String
  property :salt, String
  property :permission_level, Integer, :default => 1
  property :password_reset_key, String
  property :timezone, String, :default => "Mountain Time (US & Canada)"
  property :email_permission, Boolean, :default => false
  property :starting_weekday, Integer, :default => 0
  property :daily_reminder_permission, Boolean, :default => false
  property :daily_reminder_time, Integer, :default => 17

  timestamps :on

  validates_presence_of :name
  validates_presence_of :email
  validates_uniqueness_of :email
  validates_presence_of :hashed_password, :message => "Password must be at least 8 characters with one number."
  validates_with_block :daily_reminder_time do
    if @daily_reminder_time.between?(0,23)
      true
    else
      [false, 'Not a valid hour value.']
    end
  end

  before :save do

  end

  def password=(pass)
    if valid_password? pass
      @password = pass
      self.salt = User.random_string(32) if !self.salt
      self.hashed_password = User.encrypt(@password, self.salt)
    end
  end

  def admin?
    self.permission_level == 10
  end

  def self.authenticate(email, pass)
    user = first(:email.like => email)
    return nil if user.nil?
    return user if User.encrypt(pass, user.salt) == user.hashed_password
    nil
  end

  def remaining_tasks
    completeTasks = self.checks(:date => Date.today.to_time.in_time_zone(self.timezone).to_date).task.to_a
    incompleteTasks = self.tasks.to_a - completeTasks
    return incompleteTasks.map { |t| t.title }
  end

  def check_today?
    return !self.checks(:date => Date.today.to_time.in_time_zone(self.timezone).to_date).count.zero?
  end

  def send_reminder_email
    return unless self.daily_reminder_permission
    user_time = Time.now.in_time_zone(self.timezone)
    puts "checking #{self.id}"
    if self.remaining_tasks.length > 0
      puts "remaining tasks for #{self.id}"
      if ((user_time.hour == self.daily_reminder_time) && (user_time.min == 0)) || ((user_time.hour == self.daily_reminder_time - 1) && (user_time.min.between?(55,60)))
        puts "sending email to #{self.id}"

        title = "Remember to complete your Standards today!"
        text = "<ul>"
        self.remaining_tasks.each do |task|
          text << "<li>#{ task }</li>"
        end
        text << "</ul>"

        # Note that we can't use Sinatra's nice erb method inside here
        template = File.open('app/views/email.erb', 'r').read
        renderer = ERB.new(template)
        html_result = renderer.result(binding)
        if ENV['RACK_ENV'] != 'test'
          RestClient.post "https://api:key-3hcm94659ino89z6q586zrcw7noy7254"\
                          "@api.mailgun.net/v2/app3449307.mailgun.org/messages",
                          :from => "Standards <standards@brandonevans.ca>",
                          :to => self.email,
                          :subject => "Today's Reminder",
                          :html => html_result
        end
      end
    end
  end

  protected

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass+salt)
  end

  def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def valid_password?(password)
    return (password.length >= 8) ? true : false
  end
end
