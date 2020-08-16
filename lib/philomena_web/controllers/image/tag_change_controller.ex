defmodule PhilomenaWeb.Image.TagChangeController do
  use PhilomenaWeb, :controller

  alias Philomena.Images.Image
  alias Philomena.TagChanges.TagChange
  alias Philomena.SpoilerExecutor
  alias Philomena.Repo
  import Ecto.Query

  plug PhilomenaWeb.CanaryMapPlug, index: :show
  plug :load_and_authorize_resource, model: Image, id_name: "image_id", persisted: true

  def index(conn, params) do
    image = conn.assigns.image

    tag_changes =
      TagChange
      |> where(image_id: ^image.id)
      |> added_filter(params)
      |> preload([:tag, :user, image: [:user]])
      |> order_by(desc: :created_at)
      |> Repo.paginate(conn.assigns.scrivener)

    spoilers =
      SpoilerExecutor.execute_spoiler(
        conn.assigns.compiled_spoiler,
        Enum.map(tag_changes, & &1.image)
      )

    render(conn, "index.html",
      title: "Tag Changes on Image #{image.id}",
      image: image,
      tag_changes: tag_changes,
      spoilers: spoilers
    )
  end

  defp added_filter(query, %{"added" => "1"}),
    do: where(query, added: true)

  defp added_filter(query, %{"added" => "0"}),
    do: where(query, added: false)

  defp added_filter(query, _params),
    do: query
end
