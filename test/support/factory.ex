defmodule ExMachina.TestFactory do
  use ExMachina.Ecto, repo: ExMachina.TestRepo

  def user_factory do
    %ExMachina.User{
      name: "John Doe",
      admin: false
    }
  end

  def article_factory do
    %ExMachina.Article{
      title: "My Awesome Article",
      author: build(:user)
    }
  end

  def user_map_factory do
    %{
      id: 3,
      name: "John Doe",
      admin: false
    }
  end
end
