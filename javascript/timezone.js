// Get user timezone
let userTimezone = new Date().toString().match(/GMT([^ ]+)/)[1];
document.cookie = `user_timezone=${userTimezone.slice(0, 3)}:${userTimezone.slice(3,5)};secure`;