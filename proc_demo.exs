#
# Demonstrate processes and receiving messages
#
# DGC: 5/25/16
#
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

  #
  # Change order of backends; note how Sleeper (hang) makes the other
  # messages wait to appear
  #
  @backends [ProcDemo.Wolfram, ProcDemo.Sleeper, ProcDemo.Woogle, ProcDemo.Boomer]

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
    IO.puts "Created process #{backend}, PID: #{inspect(pid)}"
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, opts) do
    IO.puts "List of children -------------"
    IO.inspect(children)
    timeout = opts[:timeout] || 9000
    timer = Process.send_after(self(), :timeout, timeout)
    IO.puts "Messages ------------"
    # use recursion with an accumulator to gather results
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    #
    # print when a message is received
    #
    receive do
      {:results, ^query_ref, results} ->
        IO.puts "Recv rslt: #{inspect(pid)}"
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        IO.puts "Recv DWN: #{inspect(pid)}"
        await_result(tail, acc, timeout)
      :timeout ->
        IO.puts "Recv TO: #{inspect(pid)}"
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout ->
        IO.puts "Recv ATO: #{inspect(pid)}"
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
      0 -> :ok
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
  defp fetch_xml(_query_str) do
    _body = "Hello"
  end
end

defmodule ProcDemo.Woogle do
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
    results = [%Result{backend: "woogle", score: 97, text: to_string(answer)}]
    send(owner, {:results, query_ref, results})
  end

  defp fetch_xml(_query_str) do
    _body = "World!"
  end
end

defmodule ProcDemo.Boomer do

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(_query_str, _query_ref, _owner, _limit) do
    #
    # demonstrate a process crash
    #
    raise "boom!"
  end
end

defmodule ProcDemo.Sleeper do

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(_query_str, _query_ref, _owner, _limit) do
    #
    # demonstrate a hung process
    #
    :timer.sleep(:infinity)
  end
end

#
# Start the supervisor
#
ProcDemo.start(1,1)

IO.inspect ProcDemo.compute("1 + 1")


