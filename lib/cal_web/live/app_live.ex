defmodule CalWeb.AppLive do
  use CalWeb, :live_view

  def mount(_params, _session, socket) do

    # We fetch the access token to make the requests.
    # If none is found, we redirect the user to the home page.
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
