defmodule RaffleBot.Discord.MockApi do
  @moduledoc """
  A mock implementation for the Discord API behaviour using Mox.
  """

  @behaviour RaffleBot.Discord.Api

  @impl true
  def create_message(_channel_id, _content, _opts \\ []) do
    {:ok, %{}}
  end

  @impl true
  def edit_message(_channel_id, _message_id, _content, _opts \\ []) do
    {:ok, %{}}
  end

  @impl true
  def delete_message(_channel_id, _message_id, _opts \\ []) do
    {:ok, %{}}
  end

  @impl true
  def create_interaction_response(_interaction, _response_type, _data) do
    :ok
  end

  @impl true
  def edit_interaction_response(_interaction, _data) do
    :ok
  end

  @impl true
  def get_user(_user_id) do
    {:ok, %{}}
  end
end
