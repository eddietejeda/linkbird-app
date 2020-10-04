// Get user timezone
user_timezone = new Date().toString().match(/GMT([^ ]+)/)[1];
document.cookie = `user_timezone=${user_timezone.slice(0, 3)}:${user_timezone.slice(3,5)};secure`;