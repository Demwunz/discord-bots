defmodule RaffleBot.Discord.Components.ControlPanel do
  @moduledoc """
  Builds components for the admin control panel.

  The control panel is a pinned post in the admin forum channel that provides
  a central location for raffle management actions like creating new raffles
  and viewing active raffles.
  """

  alias RaffleBot.Raffles.Raffle

  @doc """
  Builds the control panel embed.

  Displays an overview of the raffle management system with quick stats.

  ## Parameters

    * `active_raffles` - List of currently active Raffle structs (optional)

  ## Returns

    A Discord embed map
  """
  def build_embed(active_raffles \\ []) do
    active_count = length(active_raffles)

    %{
      title: "🎰 Raffle Control Panel",
      description: """
      Welcome to the Raffle Bot control panel. Use the buttons below to manage raffles.

      **Quick Actions:**
      - Click **Create New Raffle** to start a new raffle
      - Click **List Active Raffles** to see all ongoing raffles
      """,
      color: 0x5865F2,
      fields: [
        %{
          name: "Active Raffles",
          value: "#{active_count}",
          inline: true
        }
      ],
      footer: %{
        text: "Raffle Bot | Admin Panel"
      },
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  @doc """
  Builds the control panel action buttons.

  Provides buttons for creating new raffles and listing active raffles.

  ## Returns

    A list of action row components
  """
  def build_buttons do
    [
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: 3,
            label: "Create New Raffle",
            custom_id: "control_panel_create_raffle",
            emoji: %{name: "🎟️"}
          },
          %{
            type: 2,
            style: 1,
            label: "List Active Raffles",
            custom_id: "control_panel_list_raffles",
            emoji: %{name: "📋"}
          }
        ]
      }
    ]
  end

  @doc """
  Builds a complete control panel message with embed and buttons.

  ## Parameters

    * `active_raffles` - List of currently active Raffle structs (optional)

  ## Returns

    A map with :embeds and :components keys suitable for Discord API
  """
  def build_message(active_raffles \\ []) do
    %{
      embeds: [build_embed(active_raffles)],
      components: build_buttons()
    }
  end

  @doc """
  Builds an embed showing the list of active raffles.

  Used when the "List Active Raffles" button is clicked.

  ## Parameters

    * `raffles` - List of active Raffle structs

  ## Returns

    A Discord embed map
  """
  def build_active_raffles_embed(raffles) when is_list(raffles) do
    case raffles do
      [] ->
        %{
          title: "📋 Active Raffles",
          description:
            "No active raffles at the moment.\n\nClick **Create New Raffle** to start one!",
          color: 0x99AAB5
        }

      raffles ->
        raffle_list =
          raffles
          |> Enum.map(fn %Raffle{} = raffle ->
            thread_link = if raffle.channel_id, do: "<##{raffle.channel_id}>", else: "N/A"
            "**#{raffle.title}** - $#{raffle.price}/spot - #{thread_link}"
          end)
          |> Enum.join("\n")

        %{
          title: "📋 Active Raffles (#{length(raffles)})",
          description: raffle_list,
          color: 0x57F287,
          footer: %{
            text: "Click on a thread link to view the raffle"
          }
        }
    end
  end
end
