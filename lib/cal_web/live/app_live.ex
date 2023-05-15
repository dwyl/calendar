defmodule CalWeb.AppLive do
  use CalWeb, :live_view
  import CalWeb.AppHTML

  def mount(params, session, socket) do
    case connected?(socket) do
      true -> connected_mount(params, session, socket)
      false -> {:ok, assign(socket, event_list: [])}
    end
  end

  def connected_mount(_params, _session, socket) do
    # Getting information about the timezone of the client
    hoursFromUTC = Map.get(get_connect_params(socket), "hoursFromUTC", "+0000")
    timezone = Timex.Timezone.name_of(hoursFromUTC)
    # We fetch the access token to make the requests.
    # If none is found, we redirect the user to the home page.
    case get_access_token(socket) do
      {:ok, access_token} ->

        dbg(Timex.now(timezone))
        {:ok, primary_calendar} = Gcal.get_calendar_details(access_token, "primary")
        # Get event list and update socket
        {:ok, event_list} = Gcal.get_event_list(access_token, Timex.now(timezone))
        {:ok, assign(socket, event_list: event_list.items, calendar: primary_calendar)}

      _ ->
        {:ok, push_redirect(socket, to: ~p"/")}
    end
  end

  # Handler to list all the events
  # Receives a date so all the events of the given date are queried.
  # It also receives the `hoursFromUTC` timezone in military hours (e.g. +0300) to properly set the timezone of the date to be queried.
  def handle_event(
        "change-date",
        %{"year" => year, "month" => month, "day" => day, "hoursFromUTC" => hoursFromUTC},
        socket
      ) do
    # Get token from socket and primary calendar
    {:ok, access_token} = get_access_token(socket)

    # Parse new date
    datetime =
      Timex.parse!("#{year}-#{month}-#{day} #{hoursFromUTC}", "{YYYY}-{M}-{D} {Z}")
      |> Timex.to_datetime()

    {:ok, new_event_list} = Gcal.get_event_list(access_token, datetime)

    # Update socket assigns
    {:noreply, assign(socket, event_list: new_event_list.items)}
  end

  # Handler to create an event.
  # Receives the title of the event, the date, the start and stop timestamps and a boolean stating if it's an "all-day" event or not.
  # It also receives the `hoursFromUTC` timezone in military hours (e.g. +0300) to properly set the timezone of the event when it's created.
  @doc """
  `event_details` typically contains the following fields:
  %{
    "all_day" => false,
    "date" => "2023-05-15",
    "hoursFromUTC" => "+0100",
    "start" => "16:00",
    "stop" => "18:00",
    "title" => "My Awesome Event"
  }
  """
  def handle_event("create-event", event_details, socket) do
    event_details = Useful.atomize_map_keys(event_details)
    # Get token and primary calendar
    {:ok, access_token} = get_access_token(socket)

    # Post new event
    {:ok, _event} = Gcal.create_event(access_token, event_details)

    # Parse new date to datetime and fetch events to refresh
    datetime =
      Timex.parse!(event_details.date, "{YYYY}-{M}-{D}")
      |> Timex.to_datetime(Timex.Timezone.name_of(event_details.hoursFromUTC))

    {:ok, new_event_list} = Gcal.get_event_list(access_token, datetime)

    {:noreply, assign(socket, event_list: new_event_list.items)}
  end

  # Get token from the flash session
  defp get_access_token(socket) do
    case Map.get(socket.assigns.flash, "token") do
      nil -> {:error, nil}
      token ->
        {:ok, token.access_token}
    end
  end
end
