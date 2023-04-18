defmodule CalWeb.AppController do
  use CalWeb, :controller

  def app(conn, _params) do

    # We fetch the access token to make the requests.
    # If none is found, we redirect the user to the home page.
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

    # person_email = get_flash(conn, :person_email)

    ## Tries to fetch the token from the DETS.
    #user_token = TokenTable.fetch_user_token(person_email)
    #if (is_nil(user_token)) do

    #  flash_token = get_flash(conn, :token)

    #  # If the token is in the flash assigns, we add it to the DETS table
    #  # and return the token
    #  if(is_nil(flash_token)) do
    #    {:error, nil}
    #  else
    #    TokenTable.create_or_update_user_token(%{person_email: person_email, token: flash_token})
    #    {:ok, flash_token}
    #  end

    #else
    #  {:ok, user_token.token}
    #end
  #end
end
