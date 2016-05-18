defmodule ExMachina.DeferredAttribute do
  @moduledoc """
  Defines a struct that enables deferred attributes in a factory.

  Fields:

  * `weight` - Defines the numeric in which deferred attributes are computed.
    Lower values are computed before higher values.  Should be an Integer.
    Defaults to 0.
  * `func` - A function which computes the attribute value.  The function should
    receive a single argument, which is the current state of the factory during
    build at the point at which the function is "undeferred".  See
    `ExMachina.defer/2`.
  """

  defstruct weight: 0, func: nil
end
