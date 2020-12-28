slack 0.1.0
===========
Please see
- https://slack.com
- https://api.slack.com/tutorials/slack-apps-hello-world

`slack::message_webhook`
-----------------
- Send a message using incoming webhook `SLACK_WEBHOOK_URL`

`slack::message`
-----------------
- Send a message using `https://slack.com/api/chat.postMessage`

`slack::upload`
-----------------
- Send a message using `https://slack.com/api/files.upload`


Dependencies
============
none


Examples
========
```
$ bee slack::message_webhook "Hello, World!"

# bee slack::message <channel> <message> <optional parent timestamp>
$ bee slack::message 12345 "Hello" "parent_ts"

# bee slack::upload <channels> <message> <file path> <optional parent timestamp>
$ bee slack::upload 12345 "Hello" "log.txt" 54321
```
