defmodule CalWeb.AppLive do
  use CalWeb, :live_view
  import CalWeb.AppHTML
  import Cal.HTTPoison

  def mount(params, session, socket) do
    case connected?(socket) do
      true -> connected_mount(params, session, socket)
      false -> {:ok, assign(socket, event_list: [])}
    end
  end

  def connected_mount(_params, _session, socket) do
    # Getting information about the timezone of the client
    hoursFromUTC = Map.get(get_connect_params(socket), "hoursFromUTC", "+0000")
    dbg(hoursFromUTC)
    timezone = Timex.Timezone.name_of(hoursFromUTC)
    dbg(timezone)
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
  def handle_event(
        "create-event",
        %{
          "title" => title,
          "date" => date,
          "start" => start,
          "stop" => stop,
          "all_day" => all_day,
          "hoursFromUTC" => hoursFromUTC
        },
        socket
      ) do
    # Get token and primary calendar
    {:ok, access_token} = get_access_token(socket)

    event_details = %{
      "title" => title,
      "date" => date,
      "start" => start,
      "stop" => stop,
      "all_day" => all_day,
      "hoursFromUTC" => hoursFromUTC
    }
    # Post new event
    {:ok, _event} = Gcal.create_event(access_token, event_details)

    # Parse new date to datetime and fetch events to refresh
    datetime =
      Timex.parse!(date, "{YYYY}-{M}-{D}")
      |> Timex.to_datetime(Timex.Timezone.name_of(hoursFromUTC))

    {:ok, new_event_list} = Gcal.get_event_list(access_token, datetime)

    {:noreply, assign(socket, event_list: new_event_list.items)}
  end

  # Gets the event list of primary calendar.
  # We pass on the `token` and the `datetime` of the day to fetch the events.
  # defp get_event_list(token, datetime) do
  #   headers = [Authorization: "Bearer #{token.access_token}", "Content-Type": "application/json"]
  #
  #   # Get primary calendar
  #   {:ok, primary_calendar} =
  #     httpoison().get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
  #     |> parse_body_response()
  #
  #   # Get events of primary calendar
  #   params = %{
  #     singleEvents: true,
  #     timeMin: datetime |> Timex.beginning_of_day() |> Timex.format!("{RFC3339}"),
  #     timeMax: datetime |> Timex.end_of_day() |> Timex.format!("{RFC3339}")
  #   }
  #
  #   {:ok, event_list} =
  #     httpoison().get(
  #       "https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events",
  #       headers,
  #       params: params
  #     )
  #     |> parse_body_response()
  #
  #   {primary_calendar, event_list}
  # end

  # Create new event to the primary calendar.
  # defp create_event(token, %{
  #        "title" => title,
  #        "date" => date,
  #        "start" => start,
  #        "stop" => stop,
  #        "all_day" => all_day,
  #        "hoursFromUTC" => hoursFromUTC
  #      }) do
  #   headers = [Authorization: "Bearer #{token.access_token}", "Content-Type": "application/json"]
  #
  #   # Get primary calendar
  #   {:ok, primary_calendar} =
  #     httpoison().get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
  #     |> parse_body_response()
  #
  #   # Setting `start` and `stop` according to the `all-day` boolean,
  #   # If `all-day` is set to true, we should return the date instead of the datetime,
  #   # as per https://developers.google.com/calendar/api/v3/reference/events/insert.
  #   start =
  #     case all_day do
  #       true ->
  #         %{date: date}
  #
  #       false ->
  #         %{
  #           dateTime:
  #             Timex.parse!("#{date} #{start} #{hoursFromUTC}", "{YYYY}-{0M}-{D} {h24}:{m} {Z}")
  #             |> Timex.format!("{RFC3339}")
  #         }
  #     end
  #
  #   stop =
  #     case all_day do
  #       true ->
  #         %{date: date}
  #
  #       false ->
  #         %{
  #           dateTime:
  #             Timex.parse!("#{date} #{stop} #{hoursFromUTC}", "{YYYY}-{0M}-{D} {h24}:{m} {Z}")
  #             |> Timex.format!("{RFC3339}")
  #         }
  #     end
  #
  #   # Post new event
  #   body = Jason.encode!(%{summary: title, start: start, end: stop})
  #
  #   httpoison().post(
  #     "https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events",
  #     body,
  #     headers
  #   )
  # end

  # Get token from the flash session
  defp get_access_token(socket) do
    case Map.get(socket.assigns.flash, "token") do
      nil -> {:error, nil}
      token ->
        {:ok, token.access_token}
    end
  end

  # Parse JSON body response
  # defp parse_body_response({:ok, response}) do
  #   body = Map.get(response, :body)
  #   # make keys of map atoms for easier access in templates
  #   if body == nil do
  #     {:error, :no_body}
  #   else
  #     {:ok, str_key_map} = Jason.decode(body)
  #     atom_key_map = for {key, val} <- str_key_map, into: %{}, do: {String.to_atom(key), val}
  #     {:ok, atom_key_map}
  #   end
  #
  #   # https://stackoverflow.com/questions/31990134
  # end
end
