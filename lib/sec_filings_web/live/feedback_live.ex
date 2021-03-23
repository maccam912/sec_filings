defmodule SecFilingsWeb.FeedbackLive do
  use SecFilingsWeb, :live_view
  import Ecto.Query, warn: false

  def feedback() do
    SecFilings.Repo.all(from(f in SecFilings.Feedback))
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, feedback: feedback())}
  end
end
