defmodule ExMachina.EctoEmbedsTest do
  use ExMachina.EctoCase
  alias ExMachina.TestRepo

  defmodule User do
    use Ecto.Schema
    schema "users" do
      field :name, :string
      field :admin, :boolean
      embeds_one :settings, ExMachina.EctoEmbedsTest.Settings
    end
  end

  defmodule Settings do
    use Ecto.Schema
    embedded_schema do
      field :email_signature
      field :send_emails, :boolean
    end
  end

  defmodule Factory do
    use ExMachina.Ecto, repo: TestRepo

    def factory(:settings) do
      %Settings{
        email_signature: "Mr. John Doe",
        send_emails: true
      }
    end

    def factory(:user) do
      %User{
        name: "John Doe",
        admin: false,
        settings: build(:settings)
      }
    end
  end

  test "insert/1 saves `embeds_one` record defined in the factory" do
    Factory.insert(:user)

    user = TestRepo.first!(User)
    assert %{settings: %{email_signature: "Mr. John Doe", send_emails: true}} = user
  end

  test "insert/2 saves `embeds_one` record when overridden" do
    settings = %Settings{email_signature: "Mrs. Jane Doe"}
    Factory.insert(:user, settings: settings)

    user = TestRepo.first!(User)
    assert user.settings.email_signature == settings.email_signature
  end
end
