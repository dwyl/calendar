defmodule CalWeb.AppLive do
  use CalWeb, :live_view
  import CalWeb.AppHTML

  def mount(_params, _session, socket) do

    # We fetch the access token to make the requests.
    # If none is found, we redirect the user to the home page.
    case get_token(socket) do
      {:ok, token} ->

        # Get event list and update socket
        {primary_calendar, event_list} = get_event_list(token, Timex.now)
        {:ok, assign(socket, event_list: event_list.items, calendar: primary_calendar)}

      _ ->
        {:ok, push_redirect(socket, to: ~p"/")}
    end
  end


  def handle_event("change-date", %{"year" => year, "month" => month, "day" => day}, socket) do

    # Get token from socket and primary calendar
    {:ok, token} = get_token(socket)

    # Parse new date
    datetime = Timex.parse!("#{year}-#{month}-#{day}", "{YYYY}-{M}-{D}") |> Timex.to_datetime()

    {_primary_calendar, new_event_list} = get_event_list(token, datetime)

    # Update socket assigns
    {:noreply, assign(socket, event_list: new_event_list.items)}
  end


  def handle_event("create-event", %{"title" => title, "date" => date, "start" => start, "stop" => stop, "all_day" => all_day}, socket) do

    # Get token and primary calendar
    {:ok, token} = get_token(socket)

    # Post new event
    {:ok, _response} = create_event(token, %{"title" => title, "date" => date, "start" => start, "stop" => stop, "all_day" => all_day})

    # Parse new date to datetime and fetch events to refresh
    datetime = Timex.parse!(date, "{YYYY}-{M}-{D}") |> Timex.to_datetime()
    {_primary_calendar, new_event_list} = get_event_list(token, datetime)

    {:noreply, assign(socket, event_list: new_event_list.items)}
  end


  # Gets the event list of primary calendar.
  # We pass on the `token` and the `datetime` of the day to fetch the events.
  defp get_event_list(token, datetime) do

    headers = ["Authorization": "Bearer #{token.access_token}", "Content-Type": "application/json"]

    # Get primary calendar
    {:ok, primary_calendar} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
    |> parse_body_response()

    # Get events of primary calendar
    params = %{
      singleEvents: true,
      timeMin: datetime |> Timex.beginning_of_day() |> Timex.format!("{RFC3339}"),
      timeMax: datetime |> Timex.end_of_day() |> Timex.format!("{RFC3339}")
    }
    {:ok, event_list} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events", headers, params: params)
    |> parse_body_response()

    {primary_calendar, event_list}
  end


  # Create new event to the primary calendar.
  defp create_event(token, %{"title" => title, "date" => date, "start" => start, "stop" => stop, "all_day" => all_day}) do

    headers = ["Authorization": "Bearer #{token.access_token}", "Content-Type": "application/json"]

    # Get primary calendar
    {:ok, primary_calendar} = HTTPoison.get("https://www.googleapis.com/calendar/v3/calendars/primary", headers)
    |> parse_body_response()

    # Setting `start` and `stop` according to the `all-day` boolean,
    # If `all-day` is set to true, we should return the date instead of the datetime,
    # as per https://developers.google.com/calendar/api/v3/reference/events/insert.
    start = case all_day do
      true -> %{date: date}
      false -> %{datetime: Timex.parse!("#{date} #{start} +0000", "{YYYY}-{0M}-{D} {h24}:{m} {Z}") |> Timex.format!("{RFC3339}") }
    end

    stop = case all_day do
      true -> %{date: date}
      false -> %{datetime: Timex.parse!("#{date} #{stop} +0000", "{YYYY}-{0M}-{D} {h24}:{m} {Z}") |> Timex.format!("{RFC3339}") }
    end

    # Post new event
    body = Jason.encode!(%{summary: title, start: start, end: stop })
    HTTPoison.post("https://www.googleapis.com/calendar/v3/calendars/#{primary_calendar.id}/events", body, headers)
  end


  # Get token from the flash session
  defp get_token(socket) do
    case Phoenix.Controller.get_flash(socket, :token) do
      nil -> {:error, nil}
      token -> {:ok, token}
    end
  end


  # Parse JSON body response
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
