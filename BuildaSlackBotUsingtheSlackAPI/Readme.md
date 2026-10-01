What You're Aiming For
Exercise: Build a Slack Bot Using the Slack API

This exercise guides students through building a Slack bot. It covers authentication, event handling, and API usage.

Objective

Respond to messages in a Slack channel.
Recognize commands like /hello.
Log messages using the Slack Events API.

Instructions
Step 1: Set Up a Slack App

Create a new Slack app at https://api.slack.com/apps.
Set permissions: chat:write, channels:history.
Enable the Events API and subscribe to message events.
Install the app and save the OAuth token.
Step 2: Build the Bot with Node.js

Install Node.js from https://nodejs.org.
Initialize a project and install Bolt
npm init -y npm install @slack/bolt

Write the bot code in bot.js and start it.
Additional Resources

Slack API Documentation: https://api.slack.com
Bolt for JavaScript: https://slack.dev/bolt-js/tutorial/getting-started
Events API Guide: https://api.slack.com/apis/connections/events-api

