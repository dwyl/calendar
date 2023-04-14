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
