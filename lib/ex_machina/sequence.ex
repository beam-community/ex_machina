defmodule ExMachina.Sequence do
  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
  end

  def next(sequence_name) when is_binary(sequence_name) do
    next sequence_name, fn(n)->
      sequence_name <> to_string(n)
    end
  end

  def next(sequence_name) do
    raise(
      ArgumentError,
      "Sequence name must be a string, got #{inspect sequence_name} instead"
    )
  end

  def next(sequence_name, formatter) do
    Agent.get_and_update(__MODULE__, fn(sequences) ->
      current_value = HashDict.get(sequences, sequence_name, 0)
      new_sequences = HashDict.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end)
  end
end
