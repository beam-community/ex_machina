if Code.ensure_loaded?(StreamData) do
  defmodule ExMachina.UndefinedGeneratorError do
    @moduledoc """
    Error raised when trying to build or create a generator that is undefined.
    """

    defexception [:message]

    def exception(generator_name) do
      message = """
      No generator defined for #{inspect(generator_name)}.

      Please check for typos or define your generator:

          def #{generator_name}_generator do
            ...
          end
      """

      %__MODULE__{message: message}
    end
  end
end
