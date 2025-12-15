defmodule RaffleBot.Discord.Modals.ShippingDetails do
  @moduledoc """
  Handles the shipping details modal submission from winners.

  Saves shipping details to the raffle and notifies admin thread.
  """

  use RaffleBot.Discord.ApiConsumer
  alias Nostrum.Struct.Interaction
  alias RaffleBot.Raffles

  def handle(
        %Interaction{
          data: %{
            "custom_id" => "shipping_details_modal_" <> raffle_id,
            "components" => components
          }
        } = interaction
      ) do
    raffle = Raffles.get_raffle!(raffle_id)
    user_id = interaction.user.id

    # Extract shipping details from modal
    shipping_details = extract_shipping_details(components)

    # Save to database
    {:ok, updated_raffle} = Raffles.update_shipping_details(raffle, shipping_details)

    # Notify admin thread
    post_shipping_to_admin(updated_raffle, user_id, shipping_details)

    # Confirm to winner
    discord_api().create_interaction_response(interaction, 4, %{
      content: """
      ✅ **Shipping details submitted!**

      The raffle admin has been notified and will ship your prize soon.

      Congratulations again! 🎉
      """,
      flags: 64
    })
  end

  defp extract_shipping_details(components) do
    fields = components
    |> Enum.flat_map(fn %{"components" => inner} -> inner end)
    |> Enum.reduce(%{}, fn field, acc ->
      case field["custom_id"] do
        "shipping_name" -> Map.put(acc, "name", field["value"])
        "shipping_address" -> Map.put(acc, "address", field["value"])
        "shipping_city_state_zip" -> Map.put(acc, "city_state_zip", field["value"])
        "shipping_country" -> Map.put(acc, "country", field["value"])
        "shipping_phone" -> Map.put(acc, "phone", field["value"] || "")
        _ -> acc
      end
    end)

    fields
  end

  defp post_shipping_to_admin(raffle, user_id, details) do
    if raffle.admin_thread_id do
      phone_line = if details["phone"] && details["phone"] != "" do
        "**Phone:** #{details["phone"]}"
      else
        "**Phone:** Not provided"
      end

      content = """
      📦 **Shipping Details Received**

      **Winner:** <@#{user_id}>

      **Name:** #{details["name"]}
      **Address:**
      #{details["address"]}
      **City/State/ZIP:** #{details["city_state_zip"]}
      **Country:** #{details["country"]}
      #{phone_line}

      ✅ Ready to ship!
      """

      discord_api().create_message(
        raffle.admin_thread_id,
        "",
        [content: content]
      )
    end
  end
end
