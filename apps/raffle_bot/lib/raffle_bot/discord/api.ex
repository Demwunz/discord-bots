defmodule RaffleBot.Discord.Api do
  @moduledoc """
  Behaviour for Discord API interactions.
  """

  @callback create_message(channel_id :: integer(), content :: String.t(), opts :: Keyword.t()) ::
              {:ok, any()} | {:error, any()}
  @callback edit_message(
              channel_id :: integer(),
              message_id :: integer(),
              content :: String.t() | map(),
              opts :: Keyword.t()
            ) :: {:ok, any()} | {:error, any()}
  @callback delete_message(
              channel_id :: integer(),
              message_id :: integer(),
              opts :: Keyword.t()
            ) :: {:ok, any()} | {:error, any()}
  @callback create_interaction_response(
              interaction :: any(),
              response_type :: integer(),
              data :: map()
            ) :: :ok
  @callback edit_interaction_response(interaction :: any(), data :: map()) :: :ok
  @callback get_user(user_id :: integer()) :: {:ok, any()} | {:error, any()}
end
