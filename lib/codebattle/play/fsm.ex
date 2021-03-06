defmodule Play.Fsm do
  @moduledoc false

  @states [:initial, :waiting_opponent, :playing, :player_won, :game_over]

  use Fsm, initial_state: :initial,
    initial_data: %{
      game_id: nil,
      first_player: nil,
      second_player: nil,
      game_over: false,
      winner: nil,
      loser: nil
    }

  defstate initial do
    defevent create(params), data: data do
      next_state(:waiting_opponent, %{data | game_id: params.game_id, first_player: params.user})
    end
  end

  defstate waiting_opponent do
    defevent join(params), data: data do
      player = params[:user]
      if data.first_player.id == player.id do
        respond({:error, "You are already in game"})
      else
        next_state(:playing, %{data | second_player: player})
      end
    end
  end

  defstate playing do
    defevent complete(params), data: data do
      if is_player?(data, params.user) do
        next_state(:player_won, %{data | winner: params.user})
      else
        respond({:error, "You are not player of this game"})
      end
    end

    defevent join(_) do
      respond({:error, "Game is already playing"})
    end
  end

  defstate player_won do
    defevent complete(params), data: data do
      if can_complete?(data, params.user) do
        next_state(:game_over, %{data | loser: params.user, game_over: true})
      else
        respond({:error, "You cannot check result after win"})
      end
    end

    defevent join(_) do
      respond({:error, "Game is already playing"})
    end
  end

  defstate game_over do
    defevent _ do
      respond({:error, "Game is over"})
    end
  end

  defp is_player?(data, player) do
    Enum.member?([data.first_player.id, data.second_player.id], player.id)
  end

  defp can_complete?(data, player) do
    if is_player?(data, player) do
      !(data.winner.id == player.id)
    else
      false
    end
  end
end
