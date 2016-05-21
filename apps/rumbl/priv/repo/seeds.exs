# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Rumbl.Repo.insert!(%Rumbl.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Rumbl.Repo
alias Rumbl.Category
alias Rumbl.User
import Ecto.Query

for category <- ~w(Action Drama Romance Comedy Sci-fi) do
  Repo.get_by(Category, name: category) ||
    Repo.insert!(%Category{name: category})
end


user_params = %{name: "Wolfran", username: "wolfram", password: "wolfram"}
changeset = User.registration_changeset(%User{}, user_params)
Repo.get_by(User, username: "wolfram") ||
  Repo.insert!(changeset)
