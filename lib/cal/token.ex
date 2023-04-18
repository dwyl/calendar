defmodule TokenTable do
  alias Pockets

  @table (if Mix.env() == :prod do
            :token_table
          else
            :token_test_table
          end)
  @filepath (if Mix.env() == :prod do
               "cache.dets"
             else
               "cache_test.dets"
             end)

  def init() do
    case Pockets.new(@table, @filepath) do
      # Not testing creating a table because when testing, it loads a sample table.
      # coveralls-ignore-start
      {:ok, set} ->
        {:ok, set}

      # coveralls-ignore-end
      {:error, _} ->
        Pockets.open(@table, @filepath)
    end
  end

  def create_or_update_user_token(%{
        :person_email => person_email,
        :token => token
      }) do
    Pockets.put(@table, person_email, %{token: token})
  end

  def fetch_user_token(person_email) do
    Pockets.get(@table, person_email)
  end

  def destroy_table() do
    Pockets.destroy(@table)
  end
end
