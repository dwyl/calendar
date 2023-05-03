defmodule CalWeb.AppHTML do
  use CalWeb, :html

  @doc """
  Renders the start and end times of the event within the event item list.
  """
  def render_start_end_times(event) do
    # Converting both start and end datetimes.
    # If no datetime is found, it's because the "start" is a date,
    # meaning the event is an "all-day" event.
    #
    # See https://developers.google.com/calendar/api/v3/reference/events#resource.

    {start_type, start_datetime} =
      case Map.get(event, "start") |> Map.get("dateTime") do
        nil ->
          {:ok, date} =
            Map.get(event, "start") |> Map.get("date") |> Timex.parse("%Y-%m-%d", :strftime)

          {:date, date}

        start_datetime ->
          {:ok, datetime} = start_datetime |> Timex.parse("{RFC3339}")
          {:datetime, datetime}
      end

    {_end_type, end_datetime} =
      case Map.get(event, "end") |> Map.get("dateTime") do
        nil ->
          {:ok, date} =
            Map.get(event, "start") |> Map.get("date") |> Timex.parse("%Y-%m-%d", :strftime)

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

  @doc """
  Returns the datetime on the left side of the event item list.
  """
  def render_date(event) do
    {:ok, start_datetime} =
      case Map.get(event, "start") |> Map.get("dateTime") do
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
