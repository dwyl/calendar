<div align="center">

# `calendar`

***effortlessly know*** when everyone in your team is ***available / busy***.

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/dwyl/calendar/ci.yml?label=build&style=flat-square&branch=main)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/calendar/main.svg?style=flat-square)](http://codecov.io/github/dwyl/calendar?branch=main)
[![Hex.pm](https://img.shields.io/hexpm/v/elixir_auth_google?color=brightgreen&style=flat-square)](https://hex.pm/packages/elixir_auth_google)
[![contributions welcome](https://img.shields.io/badge/feedback-welcome-brightgreen.svg?style=flat-square)](https://github.com/dwyl/calendar/issues)
[![HitCount](https://hits.dwyl.com/dwyl/calendar.svg)](https://hits.dwyl.com/dwyl/calendar)

</div>

## Why?

Viewing your team's availability in a single view is
a time-consuming problem that all organizations face.

There are a few companies that have *attempted* to solve this problem
in a variety of ways, however there is no "*standard*" or *generally accepted*
solution to the problem

## What?

Team calendar sharing simplified.

## How?

Using the Google Calendar API, get the availability of all members
of a team and display them in a single intuitive view.

> **Note**: Please *Ask* ***lots*** *of questions 
> as issues in this repo
 so we can evolve the requirements/solution collectively.

If you're curious on how to build this, 
please check our 
[`BUILDIT.md`](./BUILDIT.md) file.


 ## Run the App

 To run the app,
 you will need to fulfil some prerequisites:
 - have a project setup in [`Google Console`](https://console.cloud.google.com/welcome?project=dwyl-calendar).
 - enable the `Calendar API`.
 - have the `CLIENT_ID` and `CLIENT_SECRET` 
in an `.env` file and export these as
environment variables.
This is so you can sign-in through Google.
You may use `.env_example`'s structure,
rename it to `.env`
and then run `source .env` to setup
these env variables.

You can find more information on the
[`2. Connecting to Google Calendar API`](./BUILDIT.md#2-connecting-to-google-calendar-api)
section of the `BUILDIT.md` file.

After cloning the project,
all you need to do is run it,
like so!

```sh
git clone git@github.com:dwyl/calendar.git
cd calendar
mix s
```

Now visit 
[`localhost:4000`](http://localhost:4000) 
in your web browser.
