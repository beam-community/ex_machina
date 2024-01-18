defmodule ExMachina.UndefinedFactoryError do
  @moduledoc """
  Error raised when trying to build or create a factory that is undefined.
  """

  defexception [:message]

  def exception(factory_name) do
    message = """
    No factory defined for #{inspect(factory_name)}.

    Please check for typos or define your factory:

        def #{factory_name}_factory do
          ...
        end
    """

    %__MODULE__{message: message}
  end
end
