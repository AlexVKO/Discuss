defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  alias Discuss.User
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    user_params = %{token: auth.credentials.token, email: auth.info.email, provider: "github"}
    changeset = User.changeset(%User{}, user_params)

    signing(conn, changeset)
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Logout") #TODO, why it doesnt work?
    |> redirect(to: topic_path(conn, :index))
  end

  defp signing(conn, changeset) do
    case find_or_create(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back")
        |> put_session(:user_id, user.id)
        |> redirect(to: topic_path(conn, :index))
      {:error, user} ->
        conn
        |> put_flash(:error, "Error signing in")
        |> redirect(to: topic_path(conn, :index))
    end
  end

  defp find_or_create(changeset) do
    case Repo.get_by(User, email: changeset.changes.email) do
      nil  -> Repo.insert(changeset)
      user -> {:ok, user}
    end
  end

end
