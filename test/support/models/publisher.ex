defmodule ExMachina.Publisher do
  use Ecto.Schema

  schema "publishers" do
    field(:pub_number, :string)
  end
end
