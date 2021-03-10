defmodule SecFilings.RawTest do
  use SecFilings.DataCase

  alias SecFilings.Raw

  describe "index" do
    alias SecFilings.Raw.Index

    @valid_attrs %{cik: 42, company_name: "some company_name", date_filed: ~D[2010-04-17], filename: "some filename"}
    @update_attrs %{cik: 43, company_name: "some updated company_name", date_filed: ~D[2011-05-18], filename: "some updated filename"}
    @invalid_attrs %{cik: nil, company_name: nil, date_filed: nil, filename: nil}

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

  describe "form_10ks" do
    alias SecFilings.Raw.Form10k

    @valid_attrs %{content: "some content", filename: "some filename"}
    @update_attrs %{content: "some updated content", filename: "some updated filename"}
    @invalid_attrs %{content: nil, filename: nil}

    def form10k_fixture(attrs \\ %{}) do
      {:ok, form10k} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Raw.create_form10k()

      form10k
    end

    test "list_form_10ks/0 returns all form_10ks" do
      form10k = form10k_fixture()
      assert Raw.list_form_10ks() == [form10k]
    end

    test "get_form10k!/1 returns the form10k with given id" do
      form10k = form10k_fixture()
      assert Raw.get_form10k!(form10k.id) == form10k
    end

    test "create_form10k/1 with valid data creates a form10k" do
      assert {:ok, %Form10k{} = form10k} = Raw.create_form10k(@valid_attrs)
      assert form10k.content == "some content"
      assert form10k.filename == "some filename"
    end

    test "create_form10k/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Raw.create_form10k(@invalid_attrs)
    end

    test "update_form10k/2 with valid data updates the form10k" do
      form10k = form10k_fixture()
      assert {:ok, %Form10k{} = form10k} = Raw.update_form10k(form10k, @update_attrs)
      assert form10k.content == "some updated content"
      assert form10k.filename == "some updated filename"
    end

    test "update_form10k/2 with invalid data returns error changeset" do
      form10k = form10k_fixture()
      assert {:error, %Ecto.Changeset{}} = Raw.update_form10k(form10k, @invalid_attrs)
      assert form10k == Raw.get_form10k!(form10k.id)
    end

    test "delete_form10k/1 deletes the form10k" do
      form10k = form10k_fixture()
      assert {:ok, %Form10k{}} = Raw.delete_form10k(form10k)
      assert_raise Ecto.NoResultsError, fn -> Raw.get_form10k!(form10k.id) end
    end

    test "change_form10k/1 returns a form10k changeset" do
      form10k = form10k_fixture()
      assert %Ecto.Changeset{} = Raw.change_form10k(form10k)
    end
  end
end
