
defmodule ProcDemo.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    children = [
      worker(ProcDemo, [], restart: :temporary)
    ]

    supervise children, strategy: :simple_one_for_one
  end
end

defmodule ProcDemo do
  use Application

  @backends [ProcDemo.Wolfram]

  defmodule Result do
    defstruct score: 0, text: nil, url: nil, backend: nil
  end

  def start(_type, _args) do
      ProcDemo.Supervisor.start_link()
  end

  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  def compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    backends = opts[:backends] || @backends

    backends
    |> Enum.map(&spawn_query(&1, query, limit))
    |> await_results(opts)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(limit)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(ProcDemo.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, opts) do
    timeout = opts[:timeout] || 9000
    timer = Process.send_after(self(), :timeout, timeout)
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
      :timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end

  defp await_result([], acc, _) do
    acc
  end

  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    receive do
      :timout -> :ok
    after
      0 -> :k
    end
  end

end

defmodule ProcDemo.Wolfram do
  alias ProcDemo.Result

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    query_str
    |> fetch_xml()
    |> send_results(query_ref, owner)
  end

  defp send_results(nil, query_ref, owner) do
    send(owner, {:results, query_ref, []})
  end
  defp send_results(answer, query_ref, owner) do
    results = [%Result{backend: "wolfram", score: 95, text: to_string(answer)}]
    send(owner, {:results, query_ref, results})
  end

  @http Application.get_env(:info_sys, :wolfram)[:http_client] || :httpc
  defp fetch_xml(query_str) do
  #    IO.puts "fx start"
  #  IO.puts query_str
  #   IO.puts app_id()

    # {:ok, {_, _, body}} = @http.request(
    #   String.to_char_list("http://api.wolframalpha.com/v2/query" <>
    #     "?appid=#{app_id()}" <>
    #     "&input=#{URI.encode(query_str)}&format=plaintext"))
  # IO.puts "fx end"

  #  IO.inspect(body)
    body = "Hello"
  end

  defp app_id, do: Application.get_env(:info_sys, :wolfram)[:app_id]
end

ProcDemo.start(1,1)

IO.inspect ProcDemo.compute("1 + 1")
receive do


end
