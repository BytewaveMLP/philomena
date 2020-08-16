defmodule PhilomenaWeb.FingerprintProfile.SourceChangeController do
  use PhilomenaWeb, :controller

  alias Philomena.SourceChanges.SourceChange
  alias Philomena.SpoilerExecutor
  alias Philomena.Repo
  import Ecto.Query

  plug :verify_authorized

  def index(conn, %{"fingerprint_profile_id" => fingerprint}) do
    source_changes =
      SourceChange
      |> where(fingerprint: ^fingerprint)
      |> order_by(desc: :created_at)
      |> preload([:user, image: [:user]])
      |> Repo.paginate(conn.assigns.scrivener)

    spoilers =
      SpoilerExecutor.execute_spoiler(
        conn.assigns.compiled_spoiler,
        Enum.map(source_changes, & &1.image)
      )

    render(conn, "index.html",
      title: "Source Changes for Fingerprint `#{fingerprint}'",
      fingerprint: fingerprint,
      source_changes: source_changes,
      spoilers: spoilers
    )
  end

  defp verify_authorized(conn, _opts) do
    case Canada.Can.can?(conn.assigns.current_user, :show, :ip_address) do
      true -> conn
      _false -> PhilomenaWeb.NotAuthorizedPlug.call(conn)
    end
  end
end
