env 'PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

every :day, at: '9:00am' do
  runner 'Assignment.send_reminders!'
end
