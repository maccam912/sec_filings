defmodule SecFilings.RawTest do
  use SecFilings.DataCase

  alias SecFilings.Raw

  describe "index" do
    alias SecFilings.Raw.Index

    @valid_attrs %{
      cik: 42,
      company_name: "some company_name",
      date_filed: ~D[2010-04-17],
      filename: "some filename",
      form_type: "10-Q"
    }
    @update_attrs %{
      cik: 43,
      company_name: "some updated company_name",
      date_filed: ~D[2011-05-18],
      filename: "some updated filename",
      form_type: "10-K"
    }
    @invalid_attrs %{cik: nil, company_name: nil, date_filed: nil, filename: nil, form_type: nil}

    def index_fixture(attrs \\ %{}) do
      {:ok, index} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Raw.create_index()

      index
    end

    test "list_index/0 returns all index" do
      index = index_fixture()
      assert Raw.list_index() == [index]
    end

    test "get_index!/1 returns the index with given id" do
      index = index_fixture()
      assert Raw.get_index!(index.id) == index
    end

    test "create_index/1 with valid data creates a index" do
      assert {:ok, %Index{} = index} = Raw.create_index(@valid_attrs)
      assert index.cik == 42
      assert index.company_name == "some company_name"
      assert index.date_filed == ~D[2010-04-17]
      assert index.filename == "some filename"
      assert index.form_type == "10-Q"
    end

    test "create_index/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Raw.create_index(@invalid_attrs)
    end

    test "update_index/2 with valid data updates the index" do
      index = index_fixture()
      assert {:ok, %Index{} = index} = Raw.update_index(index, @update_attrs)
      assert index.cik == 43
      assert index.company_name == "some updated company_name"
      assert index.date_filed == ~D[2011-05-18]
      assert index.filename == "some updated filename"
      assert index.form_type == "10-K"
    end

    test "update_index/2 with invalid data returns error changeset" do
      index = index_fixture()
      assert {:error, %Ecto.Changeset{}} = Raw.update_index(index, @invalid_attrs)
      assert index == Raw.get_index!(index.id)
    end

    test "delete_index/1 deletes the index" do
      index = index_fixture()
      assert {:ok, %Index{}} = Raw.delete_index(index)
      assert_raise Ecto.NoResultsError, fn -> Raw.get_index!(index.id) end
    end

    test "change_index/1 returns a index changeset" do
      index = index_fixture()
      assert %Ecto.Changeset{} = Raw.change_index(index)
    end
  end
end
