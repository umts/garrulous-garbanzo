exports.handler = (context, event, callback) => {
  let twiml = new Twilio.twiml.MessagingResponse();

  const now = new Date();
  const formatOptions = {
    hour: 'numeric',
    hour12: false,
    weekday: 'long',
    timeZone: 'America/New_York',
  };
  const formatter = new Intl.DateTimeFormat('en-US', formatOptions);

  const formattedDate = formatter.format(now).split(', ');
  const day = formattedDate[0];
  const hour = Number(formattedDate[1]);
  const isWeekend = ['Sunday', 'Saturday'].includes(day);

  if (hour >= context.switchover_hour || hour < context.day_start) {
    twiml.redirect({method: 'GET'}, context.eve_roster_text_url);
  } else {
    twiml.redirect({method: 'GET'}, context.day_roster_text_url);
  }
  return callback(null, twiml);
}
