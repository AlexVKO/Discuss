defmodule Discuss.TopicController do
  use Discuss.Web, :controller
  alias Discuss.Topic

  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_owner when action in [:edit, :update, :delete]


  def index(conn, _params) do
    topics = Repo.all(Topic)
    render conn, "index.html", topics: topics
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})
    render conn, "new.html", changeset: changeset
  end

  def show(conn, %{"id" => _id}) do
    redirect conn, to: topic_path(conn, :index)
  end

  def create(conn, %{"topic" => topic}) do
    changeset =
      conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic Created")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  def edit(conn, %{"id" =>  id}) do
    topic = Repo.get(Topic, id)
    render conn, "edit.html", changeset: Topic.changeset(topic), topic: topic
  end

  def update(conn, %{"topic" => topic_params, "id" => id}) do
    old_topic = Repo.get(Topic, id)
    changeset = Topic.changeset(old_topic, topic_params)

    case Repo.update(changeset) do
      {:ok, topic} ->
        conn
        |> put_flash(:info, "Topic #{topic.title} updated")
        |> redirect(to: topic_path(conn, :index))
      {:error, changeset} ->
        render conn, "edit.html", changeset: changeset, topic: old_topic
    end
  end

  def delete(conn, %{"id" => id}) do
    Repo.get!(Topic, id) |> Repo.delete!

    conn
    |> put_flash(:info, "Topic deleted")
    |> redirect(to: topic_path(conn, :index))
  end

  def check_topic_owner(conn, _params) do
    %{params: %{"id" => topic_id}} = conn

    if Repo.get(Topic, topic_id).user_id == get_session(conn, :user_id) do
      conn
    else
      conn
      |> put_flash(:error, "Cant modify")
      |> redirect(to: topic_path(conn, :index))
      |> halt()
    end
  end

end
