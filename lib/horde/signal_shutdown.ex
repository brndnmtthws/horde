defmodule Horde.SignalShutdown do
  @moduledoc false

  use GenServer
  require Logger

  def child_spec(options) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, Keyword.get(options, :signal_to)]}
    }
  end

  def init(signal_to) do
    Logger.info(fn -> "Starting #{inspect(__MODULE__)}" end)
    Process.flag(:trap_exit, true)
    {:ok, signal_to}
  end

  def terminate(reason, signal_to) do
    Logger.info(fn ->
      "Terminating #{inspect(__MODULE__)} reason: #{inspect(reason)}"
    end)

    Enum.each(signal_to, fn destination ->
      try do
        :ok = GenServer.call(destination, :horde_shutting_down)
      catch
        # Ignore errors, we don't want to blow up during the shutdown process.
        # It's possible that other processes exited or timed out.
        :exit, _reason -> nil
      end
    end)

    :ok
  end
end
