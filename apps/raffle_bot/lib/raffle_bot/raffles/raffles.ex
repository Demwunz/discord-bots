defmodule RaffleBot.Raffles do
  @moduledoc """
  The Raffles context.
  """

  import Ecto.Query, warn: false
  alias RaffleBot.Repo

  alias RaffleBot.Raffles.Raffle

  def create_raffle(attrs \\ %{}) do
    %Raffle{}
    |> Raffle.changeset(attrs)
    |> Repo.insert()
  end

  def get_raffle!(id), do: Repo.get!(Raffle, id)

  def get_raffle_by_message_id(message_id) do
    Repo.get_by(Raffle, message_id: message_id)
  end

  def list_raffles(), do: Repo.all(Raffle)

  def list_active_raffles() do
    from(r in Raffle, where: r.closed_at > fragment("NOW()"), or_where: is_nil(r.closed_at))
    |> Repo.all()
  end

  def update_raffle(%Raffle{} = raffle, attrs) do
    raffle
    |> Raffle.changeset(attrs)
    |> Repo.update()
  end

  def list_closed_raffles() do
    from(r in Raffle, where: r.closed_at < fragment("NOW()"))
    |> Repo.all()
  end
end
