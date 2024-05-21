defmodule ExMachina.Sequence do
  @moduledoc """
  Module for generating sequential values.

  Use `ExMachina.sequence/1` or `ExMachina.sequence/2` to generate
  sequential values instead of calling this module directly.
  """

  use Agent

  @doc false
  def start_link(_) do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  @doc """
  Reset all sequences so that the next sequence starts from 0

  ## Example

      ExMachina.Sequence.next("joe") # "joe0"
      ExMachina.Sequence.next("joe") # "joe1"

      ExMachina.Sequence.reset()

      ExMachina.Sequence.next("joe") # resets so the return value is "joe0"

  You can use list as well

      ExMachina.Sequence.next("alphabet_sequence", ["A", "B"]) # "A"
      ExMachina.Sequence.next("alphabet_sequence", ["A", "B"]) # "B"

      ExMachina.Sequence.reset()

      ExMachina.Sequence.next("alphabet_sequence", ["A", "B"]) # resets so the return value is "A"

  If you want to reset sequences at the beginning of every test, put it in a
  `setup` block in your test.

      setup do
        ExMachina.Sequence.reset()
      end
  """

  @spec reset() :: :ok
  def reset do
    Agent.update(__MODULE__, fn _ -> Map.new() end)
  end

  @doc """
  Reset specific sequences so long as they already exist. The sequences
  specified will be reset to 0, while others will remain at their current index.

  You can reset a single sequence,

  ## Example

      ExMachina.Sequence.next(:alphabet, ["A", "B", "C"]) # "A"
      ExMachina.Sequence.next(:alphabet, ["A", "B", "C"]) # "B"

      ExMachina.Sequence.reset(:alphabet)

      ExMachina.Sequence.next(:alphabet, ["A", "B", "C"]) # "A"

  And you can also reset multiple sequences at once,

  ## Example

      ExMachina.Sequence.next(:numeric, [1, 2, 3]) # 1
      ExMachina.Sequence.next(:numeric, [1, 2, 3]) # 2
      ExMachina.Sequence.next("joe") # "joe0"
      ExMachina.Sequence.next("joe") # "joe1"

      ExMachina.Sequence.reset(["joe", :numeric])

      ExMachina.Sequence.next(:numeric, [1, 2, 3]) # 1
      ExMachina.Sequence.next("joe") # "joe0"
  """

  @spec reset(any()) :: :ok
  def reset(sequence_names) when is_list(sequence_names) do
    Agent.update(__MODULE__, fn sequences ->
      Enum.reduce(sequence_names, sequences, &Map.put(&2, &1, 0))
    end)
  end

  def reset(sequence_name) do
    Agent.update(__MODULE__, fn sequences ->
      Map.put(sequences, sequence_name, 0)
    end)
  end

  @doc false
  def next(sequence_name) when is_binary(sequence_name) do
    next(sequence_name, &(sequence_name <> to_string(&1)))
  end

  @doc false
  def next(sequence_name) do
    raise(
      ArgumentError,
      "Sequence name must be a string, got #{inspect(sequence_name)} instead"
    )
  end

  @doc false
  def next(sequence_name, [_ | _] = list) do
    length = length(list)

    Agent.get_and_update(__MODULE__, fn sequences ->
      current_value = Map.get(sequences, sequence_name, 0)
      index = rem(current_value, length)
      new_sequences = Map.put(sequences, sequence_name, index + 1)
      {value, _} = List.pop_at(list, index)
      {value, new_sequences}
    end)
  end

  @doc false
  def next(sequence_name, formatter, opts \\ []) do
    start_at = Keyword.get(opts, :start_at, 0)

    Agent.get_and_update(__MODULE__, fn sequences ->
      current_value = Map.get(sequences, sequence_name, start_at)
      new_sequences = Map.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end)
  end
end
