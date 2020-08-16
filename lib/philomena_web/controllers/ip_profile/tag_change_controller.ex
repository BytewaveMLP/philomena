defmodule PhilomenaWeb.IpProfile.TagChangeController do
  use PhilomenaWeb, :controller

  alias Philomena.TagChanges.TagChange
  alias Philomena.SpoilerExecutor
  alias Philomena.Repo
  import Ecto.Query

  plug :verify_authorized

  def index(conn, %{"ip_profile_id" => ip} = params) do
    {:ok, ip} = EctoNetwork.INET.cast(ip)

    tag_changes =
      TagChange
      |> where(ip: ^ip)
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
      title: "Tag Changes for IP `#{ip}'",
      ip: ip,
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

  defp verify_authorized(conn, _opts) do
    case Canada.Can.can?(conn.assigns.current_user, :show, :ip_address) do
      true -> conn
      _false -> PhilomenaWeb.NotAuthorizedPlug.call(conn)
    end
  end
end
