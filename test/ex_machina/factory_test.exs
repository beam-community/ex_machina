defmodule ExMachina.EnterpriseTest do
  use ExUnit.Case

  defmodule China do
    use ExMachina.Factory

    machine :iron do
      %{iron: true}
    end
  end

  defmodule Japan do
    use ExMachina.Factory

    machine :paper do
      %{paper: true}
    end
  end

  defmodule Company do
    use ExMachina
    use Japan
    use China
  end

  test "simple factories should be able to build" do
    assert Japan.build(:paper) == %{paper: true}
    assert China.build(:iron) == %{iron: true}
  end

  test "`use Factory` should define __using__ with factories" do
    assert Company.build(:paper) == %{paper: true}
    assert Company.build(:iron) == %{iron: true}
  end
end
