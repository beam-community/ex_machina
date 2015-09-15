defmodule ExMachina.Sequence do
  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: __MODULE__)
  end

  def next(sequence_name, formatter) do
    Agent.get_and_update(__MODULE__, fn(sequences) ->
      current_value = HashDict.get(sequences, sequence_name, 0)
      new_sequences = HashDict.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end)
  end
end
