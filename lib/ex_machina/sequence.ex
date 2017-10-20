defmodule ExMachina.Sequence do
  @moduledoc """
  Module for generating sequential values.

  Use `ExMachina.sequence/1` or `ExMachina.sequence/2` to generate
  sequential values instead of calling this module directly.
  """

  @doc false
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  @doc """
  Reset all sequences so that the next sequence starts from 0

  ## Example

      ExMachina.Sequence.next("joe") # "joe0"
      ExMachina.Sequence.next("joe") # "joe1"

      ExMachina.Sequence.reset

      ExMachina.Sequence.next("joe") # resets so the return value is "joe0"

  You can use list as well

      ExMachina.Sequence.next(["A", "B"]) # "A"
      ExMachina.Sequence.next(["A", "B"]) # "B"

      Sequence.reset

      ExMachina.Sequence.next(["A", "B"]) # resets so the return value is "A"

  If you want to reset sequences at the beginning of every test, put it in a
  `setup` block in your test.

      setup do
        ExMachina.Sequence.reset
      end
  """

  @spec reset() :: :ok
  def reset do
    Agent.update(__MODULE__, fn(_) -> Map.new end)
  end

  @doc false
  def next(sequence_name) when is_binary(sequence_name) do
    next sequence_name, &(sequence_name <> to_string(&1))
  end

  @doc false
  def next(sequence_name) do
    raise(
      ArgumentError,
      "Sequence name must be a string, got #{inspect sequence_name} instead"
    )
  end

  @doc false
  def next(sequence_name, [_|_] = list) do
    length = length(list)
    Agent.get_and_update __MODULE__, fn(sequences) ->
      current_value = Map.get(sequences, sequence_name, 0)
      index = rem(current_value, length)
      new_sequences = Map.put(sequences, sequence_name, index + 1)
      {value, _} = List.pop_at(list, index)
      {value, new_sequences}
    end
  end

  @doc false
  def next(sequence_name, formatter) do
    Agent.get_and_update __MODULE__, fn(sequences) ->
      current_value = Map.get(sequences, sequence_name, 0)
      new_sequences = Map.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end
  end
end
