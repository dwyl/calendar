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

Now let's go over adding a way for the user
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
the user will login into.
It's located inside the `/app` URL).
These files pertain to the view and controllers
of the **app** (located in `/app` URL) 
where the user will see the calendar events.

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