defmodule EtogWeb.ExtendedRenderEngine do
  @moduledoc false

  def render_block(module, template, do: yield),
    do: Phoenix.View.render(module, template, %{yield: yield})

  def render_block(module, template, %{named_blocks: named_blocks} = assigns, do: {:safe, [blocks]}) do
    assigns =
      Enum.with_index(blocks)
      |> Enum.reduce(Map.delete(assigns, :named_blocks), fn {block, idx}, acc ->
        Map.put(acc, elem(named_blocks, idx), {:safe, [block]})
      end)

    Phoenix.View.render(module, template, assigns)
  end

  def render_block(module, template, assigns, do: yield) do
    Phoenix.View.render(module, template, put_in(assigns[:yield], yield))
  end
end
