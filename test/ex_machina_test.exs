defmodule ExMachinaTest do
  use ExUnit.Case

  defmodule Factory do
    use ExMachina

    def user_factory do
      %{
        id: 3,
        name: "John Doe",
        admin: false
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

    def struct_factory do
      %{
        __struct__: Foo.Bar
      }
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
        Factory.build(:struct, doesnt_exist: true)
      end
    end

    test "build/2 allows factories to have full control of provided arguments" do
      assert Factory.build(:comment, name: "James") == %{
               author: "James Doe",
               username: "James-0",
               name: "James"
             }
    end

    test "build/2 allows custom (non-map) factories to be built" do
      assert Factory.build(:room_number, floor: 5) == "500"
      assert Factory.build(:room_number, floor: 5) == "501"
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
