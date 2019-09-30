defmodule PhoenixRoyaleWeb.AboutLive do
  use Phoenix.LiveView

  @doc """
  Why is this a LiveView controller? I was going to add some animations and effects to this page. I ran out of time :(
  """
  def render(_assigns) do
    Phoenix.View.render(PhoenixRoyaleWeb.AboutView, "about.html", about: about)
  end

  def mount(_session, socket) do
    {:ok, socket}
  end
end
