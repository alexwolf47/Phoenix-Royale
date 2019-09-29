defmodule PhoenixRoyaleWeb.AboutLive do
  use Phoenix.LiveView

  def render(_assigns) do
    {:ok, about} = File.read("README.md")

    about =
      about
      |> Earmark.as_html!()

    Phoenix.View.render(PhoenixRoyaleWeb.AboutView, "about.html", about: about)
  end

  def mount(_session, socket) do
    {:ok, socket}
  end
end
