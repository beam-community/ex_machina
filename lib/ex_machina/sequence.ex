defmodule ExMachina.Sequence do
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  @doc """
  Reset all sequences so that the next sequence starts from 0

  ## Example

      ExMachina.Sequence.next("joe") # "joe0"
      ExMachina.Sequence.next("joe") # "joe1"

      Sequence.reset

      ExMachina.Sequence.next("joe") # resets so the return value is "joe0"

  If you want to reset sequences at the beginning of every test, put it in a
  `setup` block in your test.

     setup do
       ExMachina.Sequence.reset
     end
  """
  def reset do
    Agent.update(__MODULE__, fn(_) -> Map.new end)
  end

  @doc false
  def next(sequence_name) when is_binary(sequence_name) do
    next sequence_name, fn(n)->
      sequence_name <> to_string(n)
    end
  end

  @doc false
  def next(sequence_name) do
    raise(
      ArgumentError,
      "Sequence name must be a string, got #{inspect sequence_name} instead"
    )
  end

  @doc false
  def next(sequence_name, formatter) do
    Agent.get_and_update(__MODULE__, fn(sequences) ->
      current_value = Map.get(sequences, sequence_name, 0)
      new_sequences = Map.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end)
  end
end
