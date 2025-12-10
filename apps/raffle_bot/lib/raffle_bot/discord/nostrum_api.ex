defmodule RaffleBot.Discord.NostrumApi do
  @moduledoc """
  The real implementation of the Discord API using Nostrum.
  """
  @behaviour RaffleBot.Discord.Api

  alias Nostrum.Api

  @impl true
  def create_message(channel_id, content, opts \\ []) do
    Api.Message.create(channel_id, [content: content] ++ opts)
  end

  @impl true
  def edit_message(channel_id, message_id, content, _opts \\ []) do
    Api.Message.edit(channel_id, message_id, content)
  end

  @impl true
  def delete_message(channel_id, message_id, _opts \\ []) do
    Api.Message.delete(channel_id, message_id)
  end

  @impl true
  def create_interaction_response(interaction, response_type, data) do
    Api.Interaction.create_response(interaction, response_type, data)
  end

  @impl true
  def edit_interaction_response(interaction, data) do
    Api.Interaction.edit_response(interaction, data)
  end

  @impl true
  def get_user(user_id) do
    Api.User.get(user_id)
  end
end
