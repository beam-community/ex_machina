defmodule ExMachina.EnterpriseTest do
  use ExUnit.Case

  defmodule China do
    use ExMachina.Factory

    factory :iron do
      %{iron: true}
    end
  end

  defmodule Japan do
    use ExMachina.Factory

    factory :paper do
      %{
        paper: true,
        type: Japan.something()
      }
    end

    def something do
      "Something"
    end
  end

  defmodule Company do
    use ExMachina
    use Japan
    use China

    machine :compound do
      %{
        paper: build(:paper),
        iron: build(:iron)
      }
    end
  end

  test "simple factories should be able to build" do
    assert Japan.build(:paper) == %{paper: true, type: "Something"}
    assert China.build(:iron) == %{iron: true}
  end

  test "`use Factory` should define __using__ with factories" do
    paper = %{paper: true, type: "Something"}
    iron = %{iron: true}

    assert Company.build(:paper) == paper
    assert Company.build(:iron) == iron
    assert Company.build(:compound) == %{paper: paper, iron: iron}
  end
end
