defmodule PhoenixRoyale.GameMap do
  def zone_size(), do: 10000
  def zone_interval(), do: 2000
  def zone_total(), do: zone_size() + zone_interval()

  def generate_map() do
    zone_one = generate_zone([], [:lighthouses], 0, zone_size())
    zone_two = generate_zone([], [:trees], 1 * zone_total(), 1 * zone_total() + zone_size())

    zone_three =
      generate_zone([], [:trees, :pipes], 2 * zone_total(), 2 * zone_total() + zone_size())

    %{zone_1: zone_one, zone_2: zone_two, zone_3: zone_three}
  end

  def generate_zone(map_so_far, _zone_objects, x, x_limit) when x > x_limit do
    Enum.reverse(map_so_far)
  end

  def generate_zone(map_so_far, zone_objects, x, x_limit) do
    {new_x, new_object} =
      case Enum.random(zone_objects) do
        :lighthouses ->
          generate_lighthouse(x)

        :trees ->
          generate_tree(x)

        :pipes ->
          generate_pipe(x)
      end

    generate_zone([new_object | map_so_far], zone_objects, new_x, x_limit)
  end

  defp generate_lighthouse(x) do
    new_lighthouse_x = x + Enum.random(400..800)
    new_lighthouse_y = Enum.random(-10..10)
    {new_lighthouse_x + Enum.random(700..1000), {:lighthouse, new_lighthouse_x, new_lighthouse_y}}
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
