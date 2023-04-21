<div align="center">

# Build it 👩‍💻 

This is a log 
of the steps taken 
to build this SPIKE.

</div>

We assume you have foundational knowledge
with Elixir and Phoenix.
If you don't, 
we suggest you visit 
[`learn-phoenix-framework`](https://github.com/dwyl/learn-phoenix-framework)
to learn more about Phoenix and Elixir.

Therefore, 
we are going to assume you have some experience
working with `Phoenix`,
and thus gloss over some implementation details.

This tutorial works with `Phoenix 1.7` 
and Elixir `1.14`.
Make sure you have these installed
so you can follow this tutorial more precisely.

- [Build it 👩‍💻](#build-it-)
- [0. Creating sample `Phoenix` project](#0-creating-sample-phoenix-project)
- [1. Adding `Google Auth` and basic flow in our app](#1-adding-google-auth-and-basic-flow-in-our-app)
- [2. Connecting to `Google Calendar API`](#2-connecting-to-google-calendar-api)
  - [2.1 Adding scopes when requesting token](#21-adding-scopes-when-requesting-token)
  - [2.2 Fetching information to test and maintaining token alive](#22-fetching-information-to-test-and-maintaining-token-alive)
- [3. Converting our `app` page to a **LiveView**](#3-converting-our-app-page-to-a-liveview)
  - [3.1 Deleting unused files](#31-deleting-unused-files)
- [4. Show the list of events from `Google Calendar API`](#4-show-the-list-of-events-from-google-calendar-api)
- [5. Adding calendar](#5-adding-calendar)
  - [5.1 Install `Alpine.js`](#51-install-alpinejs)
  - [5.2 Importing the calendar code](#52-importing-the-calendar-code)
  - [5.3 Retrieving the event lists by day](#53-retrieving-the-event-lists-by-day)


# 0. Creating sample `Phoenix` project

Let's create our sample project.
In your terminal, type:

```sh
mix phx.new cal --no-mailer --no-dashboard
```

This will create a sample `Phoenix` project
without e-mail services and dashboard.

After creating this tutorial,
please visit the 
`13. What is not tested` section in
https://github.com/dwyl/phoenix-chat-example#13-what-is-not-tested
to add `coveralls` to our application.
This will make it easier to test our application
and see the coverage of our codebase.

After doing the changes,
your `mix.exs` file should look like so.

[`mix.exs`](https://github.com/dwyl/calendar/blob/88bc9960b1513bba6963708e03d059445dfce684/mix.exs)

> **Note**
>
> Make sure you have the `aliases` similar to our files.
> With this, we can run commands like `mix c` 
> that will make it much easier to see the test coverage,
> for example.

After making these changes,
if you run `mix s`,
you'll have the app running on `localhost:4000`
and it should look like so.

<p align="center">
    <img width="832" alt="start" src="https://user-images.githubusercontent.com/17494745/232125438-f75e23bb-fc0c-4028-806b-3c50fac67fd7.png">
</p>

Awesome! 🎉

We're ready to go.


# 1. Adding `Google Auth` and basic flow in our app

Now let's go over adding a way for the person
to authenticate with `Google` in our app.

Luckily, we've developed a package
that will allow you to easily integrate Google authentication
onto the application - 
[`dwyl/elixir-auth-google`](https://github.com/dwyl/elixir-auth-google).

Follow the instructions 
and you should be able to have Google authentication working on the application.

Here are the changes you should have:

- created `GoogleAuthController` inside `lib/cal_web/controllers`.
The 
[`lib/cal_web/router.ex`](https://github.com/dwyl/calendar/blob/baae5b735c05b29c937ad132c43ce0129638a44b/lib/cal_web/router.ex#L21-L23)
file should look like so.

```elixir
  scope "/", CalWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/app", AppController, :app

    get "/auth/google/callback", GoogleAuthController, :index
  end
```

Your `GoogleAuthController`
inside [`lib/cal_web/controllers/google_auth_controller.ex` ](https://github.com/dwyl/calendar/blob/baae5b735c05b29c937ad132c43ce0129638a44b/lib/cal_web/controllers/google_auth_controller.ex)
should look like so:

```elixir
defmodule CalWeb.GoogleAuthController do
  use CalWeb, :controller

  @doc """
  `index/2` handles the callback from Google Auth API redirect.
  """
  def index(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)

    conn
    |> put_flash(:token, token)
    |> redirect(to: ~p"/app")
  end
end
```

We are using the package to get the token needed
to communicate with the Google APIs 
that control the person information.
We use `put_flash/2` to add this token 
to later be used in the `/app` URL.

- created 
[`app_controller.ex`](https://github.com/dwyl/calendar/blob/baae5b735c05b29c937ad132c43ce0129638a44b/lib/cal_web/controllers/app_controller.ex)
and [`app_html.ex`](https://github.com/dwyl/calendar/blob/baae5b735c05b29c937ad132c43ce0129638a44b/lib/cal_web/controllers/app_html.ex) 
inside `lib/cal_web/controllers`
and 
[`app.html.heex`](https://github.com/dwyl/calendar/blob/baae5b735c05b29c937ad132c43ce0129638a44b/lib/cal_web/controllers/app_html/app.html.heex) 
inside `lib/cal_web/controllers/app_html`
(`AppController` pertains to the application 
the person will login into.
It's located inside the `/app` URL).
These files pertain to the view and controllers
of the **app** (located in `/app` URL) 
where the person will see the calendar events.

Your `app_html.ex` file should look like:

```elixir
defmodule CalWeb.AppHTML do
  use CalWeb, :html

  embed_templates "app_html/*"
end
```

Your `app_controller.ex` should look like so.
Take note we use `get_flash/2` 
to use the `token` object
we've fetched earlier on the callback
during the login process.

```elixir
defmodule CalWeb.AppController do
  use CalWeb, :controller

  def app(conn, _params) do

    conn = case get_flash(conn, :token) do
      nil -> conn
      token -> assign(conn, :token, token)
    end

    render(conn, :app, layout: false)
  end
end
```

Your `app.html.heex` file will be empty.
Just a simple `<div>` with text 
to check if the flow of the app is correctly setup.

```html
<div>
    app
</div>
```

- added the login button 
inside [`lib/cal_web/controllers/page_html/home.html.heex`](https://github.com/dwyl/calendar/blob/baae5b735c05b29c937ad132c43ce0129638a44b/lib/cal_web/controllers/page_html/home.html.heex#L61-L64).

```html
<p class="mt-4 text-base leading-7 text-zinc-600">
    Build rich, interactive web applications quickly, with less code and fewer moving parts. Join our growing community of developers using Phoenix to craft APIs, HTML5 apps and more, for fun or at scale.
</p>
<!-- Start adding here -->
<p>To get started, login to your Google Account: </p>
<a href={@oauth_google_url}>
    <img src="https://i.imgur.com/Kagbzkq.png" alt="Sign in with Google" />
</a>
```

- changed `lib/cal_web/controllers/page_controller.ex`
to pass the token URL that is used in the HTML page.

```elixir
defmodule CalWeb.PageController do
  use CalWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    oauth_google_url = ElixirAuthGoogle.generate_oauth_url(conn)
    render(conn, :home, [layout: false, oauth_google_url: oauth_google_url])
  end
end
```

And that's it! 
Those were the changes needed to get auth working
with Google on our app!

# 2. Connecting to `Google Calendar API`

We are going to be using the `token`
to make requests to 
the [`Google Calendar API`](https://developers.google.com/calendar/api/guides/overview).

> **Note**
>
> Don't worry.
> For testing purposes, 
> the `Calendar API` is *free*.
> You can get rate limited if you exceed a certain quota
> of requests though.
> Please check https://developers.google.com/calendar/api/guides/quota
> for more information.

To use this API,
we need to *enable it*.
Visit https://console.cloud.google.com/
to access the Google Console 
and choose the project you've created
when setting up `elixir-auth-google`.
Search for `calendar api` in the search bar.

<p align="center">
  <img width="832" alt="calendar-1" src="https://user-images.githubusercontent.com/17494745/232466175-e00237ad-5c3d-43f8-b8e6-39b53146ffc0.png">
</p>

And enable it.

<p align="center">
  <img width="832" alt="calendar-2" src="https://user-images.githubusercontent.com/17494745/232466351-815b1b29-b92e-4a92-983c-76b074e5e981.png">
</p>

And you should be done!
You have enabled the API for the project 😃.

Now we need to add the **calendar scopes**
the person has to consent to using this API.
For this, click on the `OAuth consent screen` 
on the sidebar,
and click on `Edit App`.

<p align="center">
  <img width="832" alt="calendar-3" src="https://user-images.githubusercontent.com/17494745/232469724-1b3ad3ca-ab40-4bb4-9514-cb8f90d01919.png">
</p>

Go to the `Scopes` section
and click on `Add or Remove scopes`.
We will need to add a handful of scopes.
Please visit the list
in https://developers.google.com/calendar/caldav/v2/auth
and add them accordingly.


<p align="center">
  <img width="832" alt="calendar-3" src="https://user-images.githubusercontent.com/17494745/232469938-f6b34be4-c287-4d3d-b4a1-1fc5e4243221.png">
</p>

> You can copy the following string
> to add these scopes in one go.
> `https://www.googleapis.com/auth/calendar,https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/calendar.events,https://www.googleapis.com/auth/calendar.events.readonly,https://www.googleapis.com/auth/calendar.settings.readonly,https://www.googleapis.com/auth/calendar.addons.execute`.


<p align="center">
  <img width="832" alt="calendar-4" src="https://user-images.githubusercontent.com/17494745/232479519-9506fd85-6116-4610-866b-242ce59411ae.png">
</p>

## 2.1 Adding scopes when requesting token

After saving all of these changes,
we need to add the scopes to 
the configuration of `elixir-auth-google`.
We need to add these scopes to the package
so we can request an *access token that is allowed to do the actions detailed by the scopes*.

For this, follow the steps in https://github.com/dwyl/elixir-auth-google#optional-scopes.
We need to add the same scopes we've detailed prior
separated in commas.
For this, following the guide we've just linked,
we are going to add the following code to
`config/config.exs`.

```elixir
# Google auth variables
config :elixir_auth_google,
  google_scope: "profile email https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/calendar.settings.readonly"
```

After adding these scopes
and restarting the server by running `mix phx.server`,
when you click the sign up button,
you will prompted with the following screen.

<p align="center">
  <img width="332" alt="calendar-3" src="https://user-images.githubusercontent.com/17494745/232548327-b962ca67-4020-4fc1-b5f7-bfe23bced3a1.png">
</p>

These new scopes we've added
both to **Google Cloud Console** 
and **authorization scopes**
are sensitive scopes.
Since the project in `Google Cloud Console` 
is private,
we need to add a "test user" so they can consent
to allowing the project to see these scopes.
In our case,
we are just going to add our own e-mail so we can test it.
*You don't need to do this if the project is made public*.

If you visit https://console.cloud.google.com/,
go to the project 
and navigate to `OAuth consent screen`,
you can click on `+ ADD USERS`
and input your own e-mail.

<p align="center">
  <img width="832" alt="calendar-3" src="https://user-images.githubusercontent.com/17494745/232549550-f31ca82f-7fd6-4a9d-846b-ef5aefb168cc.png">
</p>

If you return to the application 
and try to sign in again,
the screen will ask you to proceed.

<p align="center">
  <img width="832" alt="calendar-3" src="https://user-images.githubusercontent.com/17494745/232550107-9bc0e160-fe34-46bd-80ab-7f77f81fa021.png">
</p>

And consent to the scopes we've define.
Make sure to tick all the boxes 
or else we won't be able to fetch information
from the `Google Calendar API`.

<p align="center">
  <img width="332" alt="calendar-3" src="https://user-images.githubusercontent.com/17494745/232550351-98a75394-534a-4b79-9b88-7a3373adc929.png">
</p>

After checking all the boxes 
and pressing continue,
we will now be able to use the `Google Calendar API`
to fetch all the information we need!


## 2.2 Fetching information to test and maintaining token alive

Let's take a look at the resources we want to retrieve 
from the `Calendar API` at
https://developers.google.com/calendar/api/v3/reference.

We have two important resources that we need to fetch:

- [**`calendars`**](https://developers.google.com/calendar/api/v3/reference/calendars/get),
pertaining to a calendar.
A person can have multiple calendars.
For now, let's keep it simple 
and always fetch the **primary** calendar of the logged in person.
- [**events**](https://developers.google.com/calendar/api/v3/reference/events),
which refer to an event in the calendar.

To test this, 
we are going to use 
[`HTTPoison`](https://github.com/edgurgel/httpoison)
to make HTTP requests
to the `Calendar API` endpoints.

Add the following line to the dependencies section 
in `mix.exs` 
and run `mix deps.get`.

```elixir
      {:httpoison, "~> 2.0"},
```

Now go over the `lib/cal_web/controllers/app_controller.ex`
and change the `app` function
and add two more, 
as shown below.

```elixir
  def app(conn, _params) do
    # We fetch the access token to make the requests.
    # If none is found, we redirect the person to the home page.
    case get_token(conn) do
      {:ok, token} ->

        headers = ["Authorization": "Bearer #{token.access_token}", "Content-Type": "application/json"]

        # Get primary calendar
        {:ok, primary_calendar} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
        |> parse_body_response()

        # Get events of first calendar
        params = %{
          maxResults: 20,
          singleEvents: true,
        }
        {:ok, event_list} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events", headers, params: params)
        |> parse_body_response()

        dbg(event_list)

        render(conn, :app, layout: false)

      _ ->
        conn |> redirect(to: ~p"/")
    end
  end



  defp get_token(conn) do
    case get_flash(conn, :token) do
      nil -> {:error, nil}
      token -> {:ok, token}
    end
  end


  defp parse_body_response({:error, err}), do: {:error, err}
  defp parse_body_response({:ok, response}) do
    body = Map.get(response, :body)
    # make keys of map atoms for easier access in templates
    if body == nil do
      {:error, :no_body}
    else
      {:ok, str_key_map} = Jason.decode(body)
      atom_key_map = for {key, val} <- str_key_map, into: %{}, do: {String.to_atom(key), val}
      {:ok, atom_key_map}
    end

    # https://stackoverflow.com/questions/31990134
  end
```

We've added `get_token/1` to fetch the token 
that is passed from the `conn`.
We've separated this into a different function 
because in the future, 
we may have a way to maintain the token 
in-between page refreshes.

We've also added `parse_body_response/1`
to parse the response body from the endpoints
and make it readable and usable.

Additionally, 
in `app/1`
if no token is found,
we redirect the person to the homepage.
We are retrieving the *primary calendar*
and *the list of the events of the primary calendar*
from the URL endpoints.

If you restart the server
and log in,
the terminal will print the list of events.
You should see an array of `event` resources
with the structure detailed in 
https://developers.google.com/calendar/api/v3/reference/events#resource-representations.

Great stuff! 🎉

We can now *use* this information
and show it to the person! 


# 3. Converting our `app` page to a **LiveView**

To make our page interactive 
and have real-time capabilities
(meaning it works on anyone that is connected to the channel),
we will be converting our `/app` view and controller
to use `LiveView`.

> **Note**
>
> If you are not familiar with `LiveView`,
> we recommend you check 
> [`dwyl/phoenix-liveview-chat-example`](https://github.com/dwyl/phoenix-liveview-chat-example)
> to learn more about it.
> We recommend going through this guide 
> because we are not going to focus on every detail
> during this "conversion".

For this, 
we will create a folder called `live`
inside `lib/cal_web`.
Create a file called `app_live.ex`
(the path will be `lib/call_web/live/app_live.ex`)
and paste the following code:

```elixir
defmodule CalWeb.AppLive do
  use CalWeb, :live_view

  def mount(_params, _session, socket) do

    # We fetch the access token to make the requests.
    # If none is found, we redirect the person to the home page.
    case get_token(socket) do
      {:ok, token} ->

        headers = ["Authorization": "Bearer #{token.access_token}", "Content-Type": "application/json"]

        # Get primary calendar
        {:ok, primary_calendar} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
        |> parse_body_response()

        # Get events of first calendar
        params = %{
          maxResults: 10,
          singleEvents: true,
        }
        {:ok, event_list} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events", headers, params: params)
        |> parse_body_response()

        dbg(event_list)

        {:ok, assign(socket, event_list: event_list.items)}

      _ ->
        {:ok, push_redirect(socket, to: ~p"/")}
    end
  end


  defp get_token(socket) do
    case Phoenix.Controller.get_flash(socket, :token) do
      nil -> {:error, nil}
      token -> {:ok, token}
    end
  end


  defp parse_body_response({:error, err}), do: {:error, err}
  defp parse_body_response({:ok, response}) do
    body = Map.get(response, :body)
    # make keys of map atoms for easier access in templates
    if body == nil do
      {:error, :no_body}
    else
      {:ok, str_key_map} = Jason.decode(body)
      atom_key_map = for {key, val} <- str_key_map, into: %{}, do: {String.to_atom(key), val}
      {:ok, atom_key_map}
    end

    # https://stackoverflow.com/questions/31990134
  end

end
```

As you can see,
it's **extremely** similar to 
the code present in `lib/cal_web/controllers/app_controller.ex`.
This is intentional
since `lib/call_web/live/app_live.ex` will act
as a controller to the LiveView.
The only difference is that 
we define the `mount/3` function
and assign the list of events fetched from the `Google Calendar API`
to the LiveView socket.

> We are only fetching 10 results just to keep bandwith
> to a minimum while we are developing and testing our app.
> We are doing this by setting the *query param* `maxResults` to 10.
> You can check the available *query params*
> at https://developers.google.com/calendar/api/v3/reference/events/list.

Inside `lib/call_web/live/`,
create another file called `app_live.html.heex`.
This will be the rendered view of the LiveView.
For now, just add the same code present in 
`lib/cal_web/controllers/app_html/app.html.heex`.

```html
<div>
    app
</div>
```

Our `LiveView` is using the **`layout`** present in 
`lib/cal_web/components/layouts/app.html.heex`.
This means the contents in `lib/cal_web/controllers/app_html/app.html.heex`
is being *rendered* inside the `<%= @inner_content %>` present in the layout.
The layout is rendering a header.
We don't care about the header,
so let's simplify the layout to just render the content of our LiveView.

Open `lib/cal_web/components/layouts/app.html.heex`
and change it so it looks like so.

```html
<.flash_group flash={@flash} />
<%= @inner_content %>
```

We're super close!
The last thing we need to do is 
change the `lib/cal_web/router.ex` file
so the `/app` endpoint 
is served by our newly created LiveView!

Open `lib/cal_web/router.ex`
and change the `get "/app", AppController, :app` line to:

```elixir
live "/app", AppLive
```

And that's it! 🎉


## 3.1 Deleting unused files

We can now delete the old controller and views,
since they're no longer being used.
You can now safely delete the following files:

- `lib/cal_web/controllers/app_html/app.html.heex`
- `lib/cal_web/controllers/app_controller.ex`
- `lib/cal_web/controllers/app_html.ex`

You may check all the changes needed in 
[`527105f`](https://github.com/dwyl/calendar/pull/25/commits/527105ffb1b6ea25b70f4453f9e8175d1d3c5d22).


# 4. Show the list of events from `Google Calendar API`

Now that we have the event list from the `Google Calendar API`,
let's show it to the person!
By looking at the 
[`Event` resource from the `Calendar API`](https://developers.google.com/calendar/api/v3/reference/events#resource),
we will want the following to be shown to the person:

- the `start` date/datetime.
- the `end` date/datetime.
- the `organizer`.
- the `summary` (title) of the event.

To make parsing and formatting
dates and datetimes easier,
we will be using 
[`timex`](https://hexdocs.pm/timex/getting-started.html)
to make this much easier.

Open `mix.exs` and add the following line
to the `deps` section and run `mix deps.get`.

```elixir
{:timex, "~> 3.0"},
```

We are now going to create a file in `lib/cal_web/live`
called `app_live_html.ex`.
This file will have a few functions
that will make it easier to render some of the text 
in our event item.

```elixir
defmodule CalWeb.AppHTML do
  use CalWeb, :html

  def render_start_end_times(event) do

    # Converting both start and end datetimes.
    # If no datetime is found, it's because the "start" is a date,
    # meaning the event is an "all-day" event.
    #
    # See https://developers.google.com/calendar/api/v3/reference/events#resource.

    {start_type, start_datetime} = case Map.get(event, "start") |> Map.get("dateTime") do
      nil ->
        {:ok, date} = Map.get(event, "start") |> Map.get("date") |> Timex.parse("%Y-%m-%d", :strftime)
        {:date, date}
      start_datetime ->
        {:ok, datetime} = start_datetime |> Timex.parse("{RFC3339}")
        {:datetime, datetime}
    end

    {end_type, end_datetime} = case Map.get(event, "end") |> Map.get("dateTime") do
      nil ->
        {:ok, date} = Map.get(event, "start") |> Map.get("date") |> Timex.parse("%Y-%m-%d", :strftime)
        {:date, date}
        end_datetime ->
        {:ok, datetime} = end_datetime |> Timex.parse("{RFC3339}")
        {:datetime, datetime}
    end

    # Return the string appropriately
    if(start_type == :date) do
      "All day"
    else
      {:ok, start_time} = Timex.format(start_datetime, "%H:%M", :strftime)
      {:ok, end_time} = Timex.format(end_datetime, "%H:%M", :strftime)

      "#{start_time} to #{end_time}"
    end
  end


  def render_date(event) do
    {:ok, start_datetime} = case Map.get(event, "start") |> Map.get("dateTime") do
      nil -> Map.get(event, "start") |> Map.get("date") |> Timex.parse("%Y-%m-%d", :strftime)
      start_datetime -> start_datetime |> Timex.parse("{RFC3339}")
    end

    %{
      year: start_datetime.year,
      month: Timex.month_shortname(start_datetime.month),
      day: start_datetime.day
    }
  end
end
```

We've created two functions:

- **`render_start_end_times/1`** shows the text with the 
start time and end time.
Some events span *all-day* and don't have a specific *start datetime*.
They do, however, have a *date*. 
This is why we check for both 
and return the string to be rendered to the view accordingly.
- **`render_date`** returns an object
with the day (number), month (3-character short word)
and year (number)
to be displayed in the item.

Now it's time to change `lib/cal_web/live/app_live.html.heex`!
Change it to the following.

```html
<div class="w-full p-4">
  <main role="main" class="flex w-full flex-col content-center justify-center md:flex-row">
    <!-- List of events -->

    <div class="flex flex-auto flex-col">

        <%= for event <- @event_list do %>
            <div class="relative block h-fit w-full overflow-hidden rounded-lg border border-gray-100 mt-2">
                <div class="flex flex-row">
                <div class="flex w-14 flex-col items-center justify-center bg-red-700 py-2 pl-3 pr-3 text-white">
                    <h3 class="text-xs"><%= render_date(event).month %></h3>
                    <h3 class="text-2xl font-bold"><%= render_date(event).day %></h3>
                    <h3 class="text-xs"><%= render_date(event).year %></h3>
                </div>

                <div class="ml-5 pb-2 pr-2 pt-2">
                    <div class="sm:flex sm:justify-between sm:gap-4">
                    <h3 class="text-lg font-bold text-gray-900 sm:text-xl">
                        <span class="mr-3"><%= Map.get(event, "summary") %></span>
                        <span class="rounded-full border border-indigo-500 px-3 py-1 text-xs text-indigo-500">
                        <span class="font-bold"><%= render_start_end_times(event) %></span>
                        </span>
                    </h3>
                    </div>

                    <div class="mt-1">
                    <p class="w-full text-sm text-gray-500">
                        <span>Organized by: </span>
                        <span class="font-bold"><%= Map.get(event, "organizer") |> Map.get("displayName") %></span>
                    </p>
                    </div>
                </div>
                </div>
            </div>
        <% end %>
    </div>

    <!--  Calendar and form section -->
    <div class="flex flex-auto">

    </div>
  </main>
</div>
```

You will need to add the following line to the top of 
`lib/cal_web/live/app_live.ex`
so these functions are accessible from the template
and actually *work*.

```elixir
import CalWeb.AppHTML
```

In the view template we are iterating over the 
`@event_list` socket assign 
and render the event item,
making use of the functions we've defined above.

If you run `mix phx.server` and sign in,
you will see the following in your screen.

<p align="center">
  <img width="1032" alt="list_items1" src="https://user-images.githubusercontent.com/17494745/233153988-2f806df0-87ae-4e33-9041-75c92a731d44.png">
</p>

> **Note**
>
> Your results may vary depending on your calendar events.
> For privacy reasons, 
> some of these item's information was changed.

Looking good!
We are now successfully fetching the events
and showing it to the person! 🥳


# 5. Adding calendar 

Now let's add a calendar for the person to have a way 
of selecting a date and filtering their events list
according to the chosen date.

To save time, 
we are going to use a combination of `TailwindCSS` and `AlpineJS`
to add our calendar to the page.

We are going to be using
the code from
https://tailwindcomponents.com/component/calendar-ui-with-tailwindcss-and-alpinejs.

## 5.1 Install `Alpine.js`

For this, 
we need to install [`AlpineJS`](https://alpinejs.dev/essentials/installation).
For this, locate the file
`lib/cal_web/components/layouts/root.html.heex`
and add the following line to the `<head>` tags.

```html
    <script src="https://cdn.jsdelivr.net/gh/alpinejs/alpine@v2.x.x/dist/alpine.js" defer></script>

```

Additionally, 
we need to change how the socket is instantiated 
in `assets/js/app.js` so `Alpine.js` correctly
changes the DOM
(check https://hexdocs.pm/phoenix_live_view/js-interop.html for more information).
For this, locate the `assets/js/app.js` file
and change the `let livesocket` variable instantiation 
to look like so:

```js
let liveSocket = new LiveSocket("/live", Socket, {
    dom: {
        onBeforeElUpdated(from, to){
          if(from.__x){ window.Alpine.clone(from.__x, to) }
        }
    },
    params: {_csrf_token: csrfToken}
})
```

That's it for installing `Alpine.js`!
Now let's import the code!


## 5.2 Importing the calendar code

As previously mentioned, 
we are using the calendar code 
from https://tailwindcomponents.com/component/calendar-ui-with-tailwindcss-and-alpinejs
(albeit with a few differences).

Let's do this.
Open `lib/cal_web/live/app_live.html.heex`
and locate the `<div>`
below the `<!--  Calendar and form section -->` line.
Change it to the following:

```html
    <div class="flex justify-center px-4 py-2 md:w-1/2">
      <div x-data="app()" x-init="[initDate(), getNoOfDays()]">
        <!-- Calendar -->
        <div class="container">
          <div class="overflow-hidden rounded-lg bg-white shadow">
            <div class="flex items-center justify-between px-6 py-2">
              <div>
                <span x-text="MONTH_NAMES[month]" class="text-lg font-bold text-gray-800"></span>
                <span x-text="year" class="ml-1 text-lg font-normal text-gray-600"></span>
              </div>
              <div class="rounded-lg border px-1" style="padding-top: 2px;">
                <button type="button" class="inline-flex cursor-pointer items-center rounded-lg p-1 leading-none transition duration-100 ease-in-out hover:bg-gray-200" x-bind:class="{'cursor-not-allowed opacity-25': month == 0 }" x-bind:disabled="month == 0 ? true : false" @click="month--; getNoOfDays()">
                  <svg class="inline-flex h-6 w-6 leading-none text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <div class="inline-flex h-6 border-r"></div>
                <button type="button" class="inline-flex cursor-pointer items-center rounded-lg p-1 leading-none transition duration-100 ease-in-out hover:bg-gray-200" x-bind:class="{'cursor-not-allowed opacity-25': month == 11 }" x-bind:disabled="month == 11 ? true : false" @click="month++; getNoOfDays()">
                  <svg class="inline-flex h-6 w-6 leading-none text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </button>
              </div>
            </div>

            <div class="-mx-1 -mb-1">
              <div class="flex flex-wrap">
                <template x-for="(day, index) in DAYS" x-bind:key="index">
                  <div style="width: 14.26%" class="px-2 py-2">
                    <div x-text="day" class="text-center text-sm font-bold uppercase tracking-wide text-gray-600"></div>
                  </div>
                </template>
              </div>

              <div class="flex flex-wrap border-l border-t">
                <template x-for="blankday in blankdays">
                  <div style="width: 14.28%; height: 60px" class="border-b border-r px-4 pt-2 text-center"></div>
                </template>
                <template x-for="(date, dateIndex) in no_of_days" x-bind:key="dateIndex">
                  <div style="width: 14.28%; height:60px" class="relative border-b border-r px-4 pt-2">
                    <div @click="onClickCalendarDay(date)" x-text="date" class="inline-flex h-6 w-6 cursor-pointer items-center justify-center rounded-full text-center leading-none transition duration-100 ease-in-out" x-bind:class="{'bg-blue-500 text-white': isToday(date) == true, 'text-gray-700 hover:bg-blue-200': isToday(date) == false }"></div>
                    <div style="height: 80px;" class="mt-1 overflow-y-auto">
                      <template x-for="event in events.filter(e => new Date(e.event_date).toDateString() ===  new Date(year, month, date).toDateString() )">
                        <div
                          class="mt-1 overflow-hidden rounded-lg border px-2 py-1"
                          x-bind:class="{
                                                        'border-blue-200 text-blue-800 bg-blue-100': event.event_theme === 'blue',
                                                        'border-red-200 text-red-800 bg-red-100': event.event_theme === 'red',
                                                        'border-yellow-200 text-yellow-800 bg-yellow-100': event.event_theme === 'yellow',
                                                        'border-green-200 text-green-800 bg-green-100': event.event_theme === 'green',
                                                        'border-purple-200 text-purple-800 bg-purple-100': event.event_theme === 'purple'
                                                    }"
                        >
                          <p x-text="event.event_title" class="truncate text-sm leading-tight"></p>
                        </div>
                      </template>
                    </div>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </div>

        <div class="container mt-2">
          <div class="block w-full w-full overflow-hidden rounded-lg bg-white p-8 shadow">
            <h2 class="mb-6 border-b pb-2 text-2xl font-bold text-gray-800">Add Event Details</h2>

            <div class="mb-4">
              <label class="mb-1 block text-sm font-bold tracking-wide text-gray-800">Event title</label>
              <input class="w-full appearance-none rounded-lg border-2 border-gray-200 bg-gray-200 px-4 py-2 leading-tight text-gray-700 focus:border-blue-500 focus:bg-white focus:outline-none" type="text" x-model="event_title" />
            </div>

            <div class="mb-4">
              <label class="mb-1 block text-sm font-bold tracking-wide text-gray-800">Event date</label>
              <input class="w-full appearance-none rounded-lg border-2 border-gray-200 bg-gray-200 px-4 py-2 leading-tight text-gray-700 focus:border-blue-500 focus:bg-white focus:outline-none" type="text" x-model="event_date" readonly />
            </div>

            <div class="mt-8 text-right">
              <div class="mt-8 text-right">
                <button type="button" class="mr-2 rounded-lg border border-gray-300 bg-white px-4 py-2 font-semibold text-gray-700 shadow-sm hover:bg-gray-100" @click="openEventModal = !openEventModal; clearModalFormData()">Cancel</button>
                <div class="mt-8 text-right">
                  <button type="button" class="mr-2 rounded-lg border border-gray-300 bg-white px-4 py-2 font-semibold text-gray-700 shadow-sm hover:bg-gray-100" @click="openEventModal = !openEventModal; clearModalFormData()">Cancel</button>
                  <button type="button" class="rounded-lg border border-gray-700 bg-gray-800 px-4 py-2 font-semibold text-white shadow-sm hover:bg-gray-700" @click="addEvent()">Save Event</button>
                </div>
              </div>
            </div>
          </div>

          <script>
            const MONTH_NAMES = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
            const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

            function app() {
                return {
                    month: '',
                    year: '',
                    no_of_days: [],
                    blankdays: [],
                    days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],

                    events: [],

                    event_title: '',
                    event_date: '',

                    initDate() {
                        let today = new Date();
                        this.month = today.getMonth();
                        this.year = today.getFullYear();
                        this.datepickerValue = new Date(this.year, this.month, today.getDate()).toDateString();
                    },

                    isToday(date) {
                        const today = new Date();
                        const d = new Date(this.year, this.month, date);

                        return today.toDateString() === d.toDateString() ? true : false;
                    },

                    onClickCalendarDay(date) {
                        this.event_date = new Date(this.year, this.month, date).toDateString();
                    },

                    clearModalFormData() {
                        this.event_title = ''
                        this.event_date = ''
                    },

                    addEvent() {
                        if (this.event_title == '') {
                            return;
                        }

                        // clear the form data
                        this.clearModalFormData()
                    },

                    getNoOfDays() {
                        let daysInMonth = new Date(this.year, this.month + 1, 0).getDate();

                        // find where to start calendar day of week
                        let dayOfWeek = new Date(this.year, this.month).getDay();
                        let blankdaysArray = [];
                        for ( var i=1; i <= dayOfWeek; i++) {
                            blankdaysArray.push(i);
                        }

                        let daysArray = [];
                        for ( var i=1; i <= daysInMonth; i++) {
                            daysArray.push(i);
                        }

                        this.blankdays = blankdaysArray;
                        this.no_of_days = daysArray;
                    }
                }
            }
          </script>
        </div>
      </div>
    </div>
```

This should add the calendar to the page.
If you sign in, the `/app` page
should look like so.

<p align="center">
  <img width="700" alt="with_calendar1" src="https://user-images.githubusercontent.com/17494745/233433201-93a7067d-9849-4d07-85f3-bec54a7e935a.png">
</p>

We've changed the code from the original link.
The original code contained *modals*
and we've placed the form below the calendar
and changed how `Alpine.js` was used with the calendar.
The reason we did this is because 
**modals are often anti-pattern and not used appropriately**.
If you want to know more about *why*,
please check https://github.com/dwyl/product-ux-research/issues/38.


## 5.3 Retrieving the event lists by day

Currently, the calendar by default
shows the blue dot showcasing the current date.
With this in mind, we want to fetch all the events
for the given day.
Every time a person clicks on another day,
the events list should also change according to the chosen day.

Let's change our `mount/3` function
to fetch the events of the current day.
We simply need to change the `params` variable
to look like so:

```elixir
  params = %{
    singleEvents: true,
    timeMin: Timex.now |> Timex.beginning_of_day() |> Timex.format!("{RFC3339}"),
    timeMax: Timex.now |> Timex.end_of_day() |> Timex.format!("{RFC3339}")
  }
```

The sockets assigns will also be changed.
We will assign the calendar as well,
so it can be accessed later by other event handlers, 
mainly when the person clicks on another date
on the calendar.

```elixir
  {:ok, assign(socket, event_list: event_list.items, calendar: primary_calendar)}
```

Now we're ready to change the event lists
*according to the chosen date**.
For this, we are going to define
a **hook** that we can call from the view template (`app_live.html.heex`)
to later be handled by the LiveView (`app_live.ex`).
To create this hook,
head over to `assets/js/app.js`,
create a `Hooks` varible
and add it to the liveview variable instantiation.
Like so.

```js
const Hooks = {}
Hooks.DateClick = {
    mounted() {
      window.dateClickHook = this
    },
    changeDate(year, month, day) {
        this.pushEvent('change-date', {year, month, day})
    }
}
  

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    dom: {
        onBeforeElUpdated(from, to){
          if(from.__x){ window.Alpine.clone(from.__x, to) }
        }
    },
    params: {_csrf_token: csrfToken},
    hooks: Hooks
})
```

We've created a hook called `dateClickHook`
that will now be accessible from the view template file.
This hook has a function called `changeDate`
which will create an event in the liveview file
by sending the year, month and date
the person changed to.

While we're at it,
let's create this event handler!
Head over to `lib/cal_web/live/app_live.ex`
and create a new function
with the following code:

```elixir
  def handle_event("change-date", %{"year" => year, "month" => month, "day" => day}, socket) do

    # Get token and primary calendar from socket
    {:ok, token} = get_token(socket)
    primary_calendar = socket.assigns.calendar

    # Parse new date
    datetime = Timex.parse!("#{year}-#{month}-#{day}", "{YYYY}-{M}-{D}") |> Timex.to_datetime()

    # Fetch events list of new date
    headers = ["Authorization": "Bearer #{token.access_token}", "Content-Type": "application/json"]
    params = %{
      singleEvents: true,
      timeMin: datetime |> Timex.beginning_of_day() |> Timex.format!("{RFC3339}"),
      timeMax: datetime |> Timex.end_of_day() |> Timex.format!("{RFC3339}")
    }
    {:ok, new_event_list} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events", headers, params: params)
    |> parse_body_response()

    # Update socket assigns
    {:noreply, assign(socket, event_list: new_event_list.items)}
  end
```

As you can see, since we're receiving the new date,
we are doing a similar process to what we're doing in the `mount/3` function:

- getting the token to call the `Calendar API`.
- parse the datetime we are changing into.
- calling the endpoint with the new datetime 
and fetching the event list for the new date.
- updating the socket assigns with the new event list.


We're nearly there! 🏃‍♂️

The last thing we need to do 
is to *change* our template file to accommodate these new changes!
Head over to `lib/cal_web/live/app_live.html.heex`
and locate the following line:

```html
<div class="flex flex-wrap border-l border-t">
```

Change it to:

```html
<div class="flex flex-wrap border-l border-t" phx-hook="DateClick" id="calendar-days">
```

We are using the [`phx-hook`](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)
attribute to embed the hook to the template 
so it can be accessible in the client-side.
We are going to make some changes to the 
`app()` function inside 
the `<script>` tag.

```js
            function app() {
                return {
                    month: '',
                    year: '',
                    chosen_day: '',
                    no_of_days: [],
                    blankdays: [],
                    days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],

                    events: [],

                    event_title: '',
                    event_date: '',

                    initDate() {
                        let today = new Date();
                        this.chosen_day = today.getUTCDate();
                        this.month = today.getMonth();
                        this.year = today.getFullYear();
                        this.datepickerValue = new Date(this.year, this.month, today.getDate()).toDateString();
                    },

                    isToday(day) {

                        const chosen_date = new Date(this.year, this.month, this.chosen_day);
                        const d = new Date(this.year, this.month, day);

                        return chosen_date.toDateString() === d.toDateString() ? true : false;
                    },

                    onClickCalendarDay(day) {
                        this.event_date = new Date(this.year, this.month, day).toDateString();
                        this.chosen_day = day;
                        window.dateClickHook.changeDate(this.year, this.month + 1, day);
                    },
                ....
                }
            }
```

We've added 
a `chosen_day` variable
which refers to the day the person 
is currently watching.
We've changed `isToday()`
to mark the blue dot in the calendar
to the day the person has chosen.
Finally, we are now pushing an event
to the liveview to be handled
within the `onClickCalendarDay(date)` function.

If you want to see all the changes made,
please check the commit
[51a1fe0](https://github.com/dwyl/calendar/pull/25/commits/51a1fe03116a2ad398623296c50c322dba252037#diff-2126216ecd2ff9ae9b5f0c1e84d8fecb4ee4e54dc21685f69a590c2162dec186).


