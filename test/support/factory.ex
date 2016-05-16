defmodule ExMachina.TestFactory do
  use ExMachina.Ecto, repo: ExMachina.TestRepo

  def user_factory do
    %ExMachina.User{
      name: "John Doe",
      admin: false,
      articles: [],
    }
  end

  def article_factory do
    %ExMachina.Article{
      title: "My Awesome Article",
      author: build(:user),
    }
  end

  def site_factory do
    %ExMachina.Site{
      name: "My Wonderful Blog"
    }
  end

  def article_for_site_factory do
    %ExMachina.Article{
      site: insert(:site),
      title: "My Awesome Article",
      author: &build(:user, site: &1.site),
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
