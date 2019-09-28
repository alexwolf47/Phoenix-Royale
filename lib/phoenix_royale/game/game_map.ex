defmodule PhoenixRoyale.GameMap do
  def zone_size(), do: 10000
  def zone_interval(), do: 2000
  def zone_total(), do: zone_size() + zone_interval()

  def generate_map() do
    zone_one =
      generate_zone(
        [],
        [
          :lighthouse,
          :comet,
          :comet,
          :comet,
          :elixir,
          :elixir,
          :elixir,
          :elixir,
          :elixir,
          :elixir
        ],
        0,
        zone_size()
      )

    zone_two =
      generate_zone(
        [],
        [:lighthouse, :comet, :comet, :comet, :elixir, :elixir],
        1 * zone_total(),
        1 * zone_total() + zone_size()
      )

    zone_three =
      generate_zone(
        [],
        [:lighthouse, :comet, :comet, :comet, :elixir],
        2 * zone_total(),
        2 * zone_total() + zone_size()
      )

    zone_four =
      generate_zone(
        [],
        [:lighthouse, :lighthouse, :comet, :elixir, :comet, :elixir, :elixir],
        3 * zone_total(),
        3 * zone_total() + zone_size()
      )

    zone_five =
      generate_zone(
        [],
        [:lighthouse, :comet, :comet, :comet, :comet, :comet, :elixir],
        4 * zone_total(),
        4 * zone_total() + zone_size()
      )

    %{
      zone_1: zone_one,
      zone_2: zone_two,
      zone_3: zone_three,
      zone_4: zone_four,
      zone_5: zone_five
    }
  end

  def zone_start_map() do
    [{:elixir, 500, 50}, {:elixir, 500, 75}, {:elixir, 500, 25}]
  end

  def generate_zone(map_so_far, _zone_objects, x, x_limit) when x > x_limit do
    Enum.reverse(map_so_far)
  end

  def generate_zone(map_so_far, zone_objects, x, x_limit) do
    if map_so_far == [] do
      generate_zone(zone_start_map(), zone_objects, x + 1000, x_limit)
    else
      {new_x, new_object} =
        case Enum.random(zone_objects) do
          :lighthouse ->
            generate_lighthouse(x)

          :comet ->
            generate_comet(x)

          :elixir ->
            if Enum.random(0..100) >= 4 do
              generate_elixir(x)
            else
              generate_lighthouse(x)
            end

          :trees ->
            generate_tree(x)

          :pipes ->
            generate_pipe(x)
        end

      generate_zone([new_object | map_so_far], zone_objects, new_x, x_limit)
    end
  end

  defp generate_lighthouse(x) do
    new_lighthouse_x = x + Enum.random(400..800)
    new_lighthouse_y = Enum.random(-10..10)
    {new_lighthouse_x + Enum.random(700..1000), {:lighthouse, new_lighthouse_x, new_lighthouse_y}}
  end

  defp generate_comet(x) do
    new_comet_x = x + Enum.random(300..1000)
    new_comet_y = Enum.random(20..90)
    {x + 200, {:comet, new_comet_x, new_comet_y}}
  end

  defp generate_elixir(x) do
    new_elixir_x = x + Enum.random(-1000..1200)
    new_elixir_y = Enum.random(12..95)
    {x + 200, {:elixir, new_elixir_x, new_elixir_y}}
  end

  defp generate_tree(x) do
    new_tree_x = x + Enum.random(400..800)
    new_tree_y = Enum.random(-30..90)
    new_tree_length = Enum.random(10..10)
    {new_tree_x + new_tree_length, {:tree, new_tree_x, new_tree_y, new_tree_length}}
  end

  defp generate_pipe(x) do
    new_pipe_x = x + Enum.random(2000..4000)
    new_pipe_y = Enum.random(10..90)
    {new_pipe_x, {:pipe, new_pipe_x, new_pipe_y}}
  end
end
