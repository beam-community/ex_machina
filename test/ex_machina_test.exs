defmodule ExMachinaTest do
  use ExUnit.Case

  defmodule FooBar do
    defstruct [:name]
  end

  defmodule Factory do
    use ExMachina

    def user_factory do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    def profile_factory do
      %{
        username: sequence("username"),
        user: build(:user)
      }
    end

    def account_factory do
      %{
        private: true,
        profile: fn -> build(:profile) end
      }
    end

    def admin_account_factory do
      %{
        admin: true,
        profile: fn account -> build(:profile, admin: account.admin) end
      }
    end

    def email_factory do
      %{
        email: sequence(:email, &"me-#{&1}@foo.com")
      }
    end

    def article_factory do
      %{
        title: sequence("Post Title")
      }
    end

    def foo_bar_factory do
      %FooBar{}
    end

    def comment_factory(attrs) do
      %{name: name} = attrs

      username = sequence(:username, &"#{name}-#{&1}")

      comment = %{
        author: "#{name} Doe",
        username: username
      }

      merge_attributes(comment, attrs)
    end

    def room_number_factory(attrs) do
      %{floor: floor_number} = attrs
      sequence(:room_number, &"#{floor_number}0#{&1}")
    end

    def money_factory do
      %{
        cents: sequence(:cents, &"#{&1}", start_at: 600)
      }
    end
  end

  describe "sequence" do
    test "sequence/2 sequences a value" do
      assert "me-0@foo.com" == Factory.build(:email).email
      assert "me-1@foo.com" == Factory.build(:email).email
    end

    test "sequence/1 shortcut for creating sequences" do
      assert "Post Title0" == Factory.build(:article).title
      assert "Post Title1" == Factory.build(:article).title
    end

    test "sequence/3 allows for setting a starting value" do
      assert "600" == Factory.build(:money).cents
      assert "601" == Factory.build(:money).cents
    end
  end

  describe "build/2" do
    test "raises a helpful error if the factory is not defined" do
      assert_raise ExMachina.UndefinedFactoryError, fn ->
        Factory.build(:foo)
      end
    end

    test "build/2 returns the matching factory" do
      assert Factory.build(:user) == %{
               id: 3,
               name: "John Doe",
               admin: false
             }
    end

    test "build/2 merges passed in options as keyword list" do
      assert Factory.build(:user, admin: true) == %{
               id: 3,
               name: "John Doe",
               admin: true
             }
    end

    test "build/2 merges passed in options as a map" do
      assert Factory.build(:user, %{admin: true}) == %{
               id: 3,
               name: "John Doe",
               admin: true
             }
    end

    test "build/2 raises if passing invalid keys to a struct factory" do
      assert_raise KeyError, fn ->
        Factory.build(:foo_bar, doesnt_exist: true)
      end
    end

    test "build/2 allows factories to have full control of provided arguments" do
      comment = Factory.build(:comment, name: "James")

      assert %{author: "James Doe", name: "James"} = comment
      assert String.starts_with?(comment[:username], "James-")
    end

    test "build/2 allows custom (non-map) factories to be built" do
      assert Factory.build(:room_number, floor: 5) == "500"
      assert Factory.build(:room_number, floor: 5) == "501"
    end

    test "build/2 accepts anonymous functions for a factory's attributes" do
      account = Factory.build(:account)

      assert %{username: _} = account.profile
    end

    test "build/2 accepts anonymous functions that use parent record in factory's definition" do
      assert %{profile: %{admin: true}} = Factory.build(:admin_account, admin: true)
      assert %{profile: %{admin: false}} = Factory.build(:admin_account, admin: false)
    end

    test "build/2 can take anonymous functions for attributes" do
      user = Factory.build(:user, foo_bar: fn -> Factory.build(:foo_bar) end)

      assert %FooBar{} = user.foo_bar
    end

    test "build/2 does not evaluate lazy attributes when factory definition has full control" do
      comment = Factory.build(:comment, name: "James", user: fn -> Factory.build(:user) end)

      assert is_function(comment.user)
      assert %{id: 3, name: "John Doe", admin: false} = comment.user.()
    end

    test "build/2 recursively builds nested lazy attributes" do
      lazy_profile = fn -> Factory.build(:profile, user: fn -> Factory.build(:user) end) end
      account = Factory.build(:account, profile: lazy_profile)

      assert %{username: _} = account.profile
      assert %{name: "John Doe", admin: false} = account.profile.user
    end

    test "build/2 lazily evaluates an attribute that is a list" do
      user = Factory.build(:user, profiles: fn -> [Factory.build(:profile)] end)

      profile = hd(user.profiles)

      assert Map.has_key?(profile, :username)
      assert Map.has_key?(profile, :user)
    end
  end

  describe "build_pair/2" do
    test "build_pair/2 builds 2 factories" do
      records = Factory.build_pair(:user, admin: true)

      expected_record = %{
        id: 3,
        name: "John Doe",
        admin: true
      }

      assert records == [expected_record, expected_record]
    end

    test "build_pair/2 recursively builds many nested lazy attributes" do
      lazy_profile = fn -> Factory.build(:profile, user: fn -> Factory.build(:user) end) end
      [account1, account2] = Factory.build_pair(:account, profile: lazy_profile)

      assert account1.profile.username != account2.profile.username
    end
  end

  describe "build_list/3" do
    test "build_list/3 builds the factory the passed in number of times" do
      records = Factory.build_list(3, :user, admin: true)

      expected_record = %{
        id: 3,
        name: "John Doe",
        admin: true
      }

      assert records == [expected_record, expected_record, expected_record]
    end

    test "build_list/3 handles the number 0" do
      assert [] = Factory.build_list(0, :user)
    end

    test "raises helpful error when using old create functions" do
      assert_raise RuntimeError, ~r/create\/1 has been removed/, fn ->
        Factory.create(:user)
      end

      assert_raise RuntimeError, ~r/create\/2 has been removed/, fn ->
        Factory.create(:user, admin: true)
      end

      assert_raise RuntimeError, ~r/create_pair\/2 has been removed/, fn ->
        Factory.create_pair(:user, admin: true)
      end

      assert_raise RuntimeError, ~r/create_list\/3 has been removed/, fn ->
        Factory.create_list(3, :user, admin: true)
      end
    end
  end
end
