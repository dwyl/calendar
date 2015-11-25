# Google Api Free Busy Request

### Google will let you query their calendar to find out when a group of people are free/busy.

You can send a sample request using the tool on their docs. This is great as you can test the information you get back without having to set up the server/auth by yourself before you know if it's useful.

The full spec of how to use it is on their docs here:
https://developers.google.com/google-apps/calendar/v3/reference/freebusy/query

### To send the request

There are 3 parameters that you need to send the request and then a whole load of optional ones which we haven't worked out yet.

These are:
- Time Min
- Time Max
- Item

#### Time Min & Time Max

These are the times within which you're searching for a person's free/busy status. It's a bit fiddly as you have to run some code to get the date in the ISO format needed for the request. e.g. YYYY-MM-DDTHH:mm:ssZ

Luckily Google have written this code in any language you might need here: https://developers.google.com/schemas/formats/datetime-formatting

The Javascript you'll need is:
```javascript
var d = new Date();
var date = d.toISOString();
```
This will give you a date that looks like this '2015-11-25T19:45:17.578Z'

#### Item

Confusingly named this is where you add the calendars of people that you would like to check the availability of. For this to work that person must have shared their calendar with you (or it would need to be public).

There's also the ability to search all the calendars of people in a group that they're part of like an organisation. We haven't tried this but it seems like each group has it's own ID and then you enter that instead of individual people's calendar ID's.

Here's a slide share of how to find out a person's calendar ID given that they've shared their calendar with you:
http://googleappstroubleshootinghelp.blogspot.co.uk/2012/09/how-to-find-calendar-id-of-google.html

You basically just click on the drop down arrow by their name in your calendar list and go to settings.

### Our sample Request and Response

#### Request
```
POST https://www.googleapis.com/calendar/v3/freeBusy?key={YOUR_API_KEY}
{
 "timeMin": "2015-11-25T12:45:17.578Z",
 "timeMax": "2015-11-25T19:45:17.578Z",
 "items": [
  {
   "id": "sample.foundersandcoders@gmail.com"
  },
  {
   "id": "ababababababbaa@group.calendar.google.com"
  }
 ]
}
```
#### Response

```
200 OK

- SHOW HEADERS -
{
 "kind": "calendar#freeBusy",
 "timeMin": "2015-11-25T12:45:17.000Z",
 "timeMax": "2015-11-25T19:45:17.000Z",
 "calendars": {
  "sample.foundersandcoders@gmail.com": {
   "busy": [
    {
     "start": "2015-11-25T16:00:00Z",
     "end": "2015-11-25T16:30:00Z"
    },
    {
     "start": "2015-11-25T19:00:00Z",
     "end": "2015-11-25T19:45:17Z"
    }
   ]
  },
  "abababababababa@group.calendar.google.com": {
   "busy": [
   ]
  }
 }
}
```

This only tells when you people are busy, not what they're doing which is useful information for scheduling.
