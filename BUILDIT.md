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
    # If none is found, we redirect the user to the home page.
    case get_token(conn) do
      {:ok, token} ->

        headers = ["Authorization": "Bearer #{token.access_token}", "Content-Type": "application/json"]

        # Get list of calendars
        {:ok, primary_calendar} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
        |> parse_body_response()


        # Get events of first calendar
        {:ok, event_list} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events", headers)
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
and show it to the user! 

