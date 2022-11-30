defmodule CsvServer do
  @moduledoc """
  Documentation for `CsvServer`.
  """
  use GenServer

  alias Explorer.DataFrame

  @impl true
  def init(%{ filename: filename, header: header}) do
    data = 
      if File.exists?(filename) do
        DataFrame.from_csv!(filename, header: header)
        |> DataFrame.to_rows(atom_keys: true)
     else
       []
     end

    {:ok, %{ filename: filename, data: data}} 
  end

  @doc """
  Handle_call than returns all data 
  """
  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.get(state, :data, []), state}
  end

  @impl true
  def handle_call(:filename, _from, state) do
    {:reply, Map.get(state, :filename, "not define"), state}
  end

  @impl true
  def handle_call(:keys, _from, state) do
    keys =
      state.data
      |> List.first()
      |> Map.keys()

    {:reply, keys, state}
  end

  @impl true
  def handle_cast({:update_keys, old_keys, new_keys}, state) do
    old_new = Enum.zip(old_keys, new_keys)
    new_data = 
      Map.get(state, :data, [])
      |> Enum.map(&Map.new(&1, fn
           {key, value} -> {Keyword.get(old_new, key, key), value}
         end))
    {:reply, %{state | data: new_data}}
  end

  @impl true
  def handle_cast({:new_filename, new_filename}, state) do
    {:noreply, %{state | filename: new_filename}}
  end

  @impl true
  def handle_cast({:insert, value}, state) do
    {:noreply, %{state | data: [ value | state.data]}}
  end

  @impl true
  def handle_cast(:save, state) do
    DataFrame.new(state.data)
    |> DataFrame.to_csv(state.filename)

    {:noreply, state }
  end

  @doc """
  Starts the csv server
  """
  def start_link(opts) do
    filename = Keyword.fetch!(opts, :filename)
    header = Keyword.get(opts, :header, true)
    tabla = Keyword.fetch!(opts, :tabla)
    GenServer.start_link(__MODULE__, %{filename: filename, header: header}, name: tabla)
  end

  def all(pid) do
    GenServer.call(pid, :all)
  end

  def get_filename(pid) do
    GenServer.call(pid, :filename)
  end

  def keys(pid) do
    GenServer.call(pid, :keys)
  end

  def save(pid) do
    GenServer.cast(pid, :save)
  end

  def insert(pid, value) do
    GenServer.cast(pid, {:insert, value})
  end

  def new_filename(pid, filename) do
    GenServer.cast(pid, {:new_filename, filename})
  end

  def rename_keys(pid, old_keys, new_keys) do
    GenServer.cast(pid, {:update_keys, old_keys, new_keys})
  end

end
