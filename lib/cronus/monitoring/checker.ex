defmodule Cronus.Monitoring.Checker do
  require Logger

  def check(url) do
    {microseconds, response} = :timer.tc(fn ->
      Req.get(url)
    end)

    milliseconds = div(microseconds, 1000)

    case response do
      {:ok, %{status: status}} when status in 200..299 ->
        {:ok, status, milliseconds}

      {:ok, %{status: status}} ->
        {:error, status, milliseconds}

      {:error, exception} ->
        Logger.error("Falha ao acessar #{url}: #{inspect(exception)}")
        {:error, :transport_error, milliseconds}
    end
  end
end
