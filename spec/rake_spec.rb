require_relative 'spec_helper.rb'
require 'active_support/core_ext/time/zones'
require 'active_support/time_with_zone'
require 'active_support/core_ext/time/conversions'
require 'stringio'
require 'rake'
require 'timecop'

module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end
end

describe 'Rake' do
  before do
    Rake::Task.define_task(:environment)
    @user1 = User.create :name => 'Mike', :email => 'evans.brandon+1@gmail.com', :password => 'Tes7yasdf', :daily_reminder_permission => true, :daily_reminder_time => 17, :timezone => 'America/New_York'
    @user2 = User.create :name => 'Mike', :email => 'evans.brandon+2@gmail.com', :password => 'Tes7yasdf', :daily_reminder_permission => false, :daily_reminder_time => 17, :timezone => 'America/New_York'
    @user3 = User.create :name => 'Mike', :email => 'evans.brandon+3@gmail.com', :password => 'Tes7yasdf', :daily_reminder_permission => true, :daily_reminder_time => 17, :timezone => 'Canada/Newfoundland'
    @user4 = User.create :name => 'Mike', :email => 'evans.brandon+4@gmail.com', :password => 'Tes7yasdf', :daily_reminder_permission => true, :daily_reminder_time => 17, :timezone => 'Asia/Katmandu'
  end

  let :run_rake_task do
    Rake::Task["reminders:daily"].reenable
    Rake::Task["reminders:daily"].invoke
  end

  describe 'reminders:daily' do
    it 'should only test users with permission' do
      result = capture_stdout do run_rake_task end
      result.string.should include 'checking 1'
      result.string.should_not include 'checking 2'
    end
    it 'should send an email at the correct time (n offset)' do
      Timecop.freeze(Time.new(2012, 1, 1, 15))
      result = capture_stdout do run_rake_task end
      result.string.should include 'sending email to 1'
      result.string.should_not include 'sending email to 3'
    end
    it 'should not send an email at the incorrect time (n offset)' do
      Timecop.freeze(Time.new(2012, 1, 1, @user1.daily_reminder_time, 10))
      result = capture_stdout do run_rake_task end
      result.string.should_not include 'sending email to 1'
      result.string.should_not include 'sending email to 3'
    end
    it 'should send an email at the correct time (n.5 offset)' do
      Timecop.freeze(Time.new(2012, 1, 1, 13, 30))
      result = capture_stdout do run_rake_task end
      result.string.should_not include 'sending email to 1'
      result.string.should include 'sending email to 3'
    end
    it 'should not send an email at the incorrect time (n.5 offset)' do
      Timecop.freeze(Time.new(2012, 1, 1, @user1.daily_reminder_time, 30))
      result = capture_stdout do run_rake_task end
      result.string.should_not include 'sending email to 1'
      result.string.should_not include 'sending email to 3'
    end
    it 'should send an email at the correct time (n.25 offset)' do
      Timecop.freeze(Time.new(2012, 1, 2, 4, 10))
      result = capture_stdout do run_rake_task end
      result.string.should_not include 'sending email to 1'
      result.string.should_not include 'sending email to 3'
      result.string.should include 'sending email to 4'
    end
    it 'should not send an email at the incorrect time (n.25 offset)' do
      Timecop.freeze(Time.new(2012, 1, 1, @user1.daily_reminder_time, 10))
      result = capture_stdout do run_rake_task end
      result.string.should_not include 'sending email to 1'
      result.string.should_not include 'sending email to 3'
      result.string.should_not include 'sending email to 4'
    end
  end
end