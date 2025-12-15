defmodule RaffleBot.Raffles do
  @moduledoc """
  The Raffles context.
  """

  import Ecto.Query, warn: false
  alias RaffleBot.Repo

  alias RaffleBot.Raffles.Raffle
  alias RaffleBot.Raffles.WinnerReroll
  alias RaffleBot.Claims

  alias RaffleBot.Closer

  def create_raffle(attrs \\ %{}) do
    %Raffle{}
    |> Raffle.changeset(attrs)
    |> Repo.insert()
    |> schedule_close()
  end

  defp schedule_close({:ok, raffle}) do
    Closer.schedule_close(raffle)
    {:ok, raffle}
  end

  defp schedule_close({:error, changeset}), do: {:error, changeset}

  def get_raffle!(id), do: Repo.get!(Raffle, id)

  def get_raffle(id), do: Repo.get(Raffle, id)

  def get_raffle_by_message_id(message_id) do
    Repo.get_by(Raffle, message_id: message_id)
  end

  def get_raffle_by_admin_thread(admin_thread_id) do
    Repo.get_by(Raffle, admin_thread_id: admin_thread_id)
  end

  def list_raffles(), do: Repo.all(Raffle)

  def list_active_raffles() do
    now = DateTime.utc_now()

    from(r in Raffle,
      where: r.closed_at > ^now or is_nil(r.closed_at),
      where: r.active == true
    )
    |> Repo.all()
  end

  def update_raffle(%Raffle{} = raffle, attrs) do
    raffle
    |> Raffle.changeset(attrs)
    |> Repo.update()
  end

  def list_closed_raffles() do
    now = DateTime.utc_now()

    from(r in Raffle,
      where: r.closed_at < ^now or r.active == false
    )
    |> Repo.all()
  end

  def close_raffle(%Raffle{} = raffle) do
    update_raffle(raffle, %{
      active: false,
      closed_at: DateTime.utc_now()
    })
  end

  # Winner Selection Functions

  @doc """
  Selects a random winner from paid claims using weighted random selection.
  Each paid spot = 1 entry. Returns the winning claim.
  """
  def select_random_winner(raffle_id) do
    paid_claims = Claims.get_paid_claims_for_raffle(raffle_id)

    if Enum.empty?(paid_claims) do
      {:error, :no_paid_claims}
    else
      # Weighted random: each claim is one entry
      winning_claim = Enum.random(paid_claims)
      {:ok, winning_claim}
    end
  end

  @doc """
  Gets all spots owned by a user in a raffle.
  """
  def get_user_spots(raffle_id, user_id) do
    Claims.get_user_claims_for_raffle(user_id, raffle_id)
    |> Enum.map(& &1.spot_number)
    |> Enum.sort()
  end

  @doc """
  Sets the winner for a raffle.
  """
  def set_winner(%Raffle{} = raffle, user_id, spot_number) do
    update_raffle(raffle, %{
      winner_user_id: to_string(user_id),
      winner_spot_number: spot_number,
      winner_announced_at: DateTime.utc_now()
    })
  end

  @doc """
  Updates shipping details for a raffle winner.
  """
  def update_shipping_details(%Raffle{} = raffle, shipping_details) do
    update_raffle(raffle, %{
      shipping_details: shipping_details,
      shipping_submitted_at: DateTime.utc_now()
    })
  end

  @doc """
  Records a winner re-roll for audit purposes.
  """
  def record_reroll(attrs) do
    %WinnerReroll{}
    |> WinnerReroll.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets all re-rolls for a raffle.
  """
  def list_rerolls(raffle_id) do
    from(r in WinnerReroll,
      where: r.raffle_id == ^raffle_id,
      order_by: [desc: r.rerolled_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists closed raffles that don't have a winner yet.
  """
  def list_closed_raffles_without_winner() do
    from(r in Raffle,
      where: r.active == false,
      where: is_nil(r.winner_user_id)
    )
    |> Repo.all()
  end
end
