defmodule Pow.Phoenix.ViewHelpers do
  @moduledoc """
  Module that renders views.

  By default, the controller views and templates in this library will be used,
  and the layout view will be based on the module namespace of the Endpoint
  module.

  By setting the `:web_module` key in config, the controller and layout views
  can be used from this context app.

  So if you set up your endpoint like this:

      defmodule MyAppWeb.Endpoint do
        plug Pow.Plug.Session
      end

  Only `MyAppWeb.LayoutView` will be used from your app. However, if you set up
  the endpoint with a `:web_module` key:

      defmodule MyAppWeb.Endpoint do
        plug Pow.Plug.Session, web_module: MyAppWeb
      end

  The following modules are will be used from your app:

    * `MyAppWeb.LayoutView`
    * `MyAppWeb.Pow.RegistrationView`
    * `MyAppWeb.Pow.SessionView`

  And also the following templates has to exist in
  `lib/my_project_web/templates/pow`:

    * `registration/new.html.eex`
    * `registration/edit.html.eex`
    * `session/new.html.eex`
  """
  alias Phoenix.Controller
  alias Plug.Conn
  alias Pow.{Config, Plug}

  @doc """
  Sets the view layout based on the pow configuration.
  """
  @spec layout(Conn.t()) :: Conn.t()
  def layout(conn) do
    config     = Plug.fetch_config(conn)
    web_module = Config.get(config, :web_module)
    view       = view(conn, web_module)
    layout     = layout(conn, web_module)

    conn
    |> Controller.put_view(view)
    |> Controller.put_layout(layout)
  end

  defp view(conn, web_module) do
    conn
    |> Controller.view_module()
    |> build_view_module(web_module)
  end

  defp layout(conn, web_module) do
    conn
    |> Controller.layout()
    |> build_layout(web_module || web_base(conn))
  end

  defp web_base(conn) do
    conn
    |> Controller.endpoint_module()
    |> split_module()
    |> Enum.reverse()
    |> case do
      ["Endpoint" | base] -> base
      base                -> base
    end
    |> Enum.reverse()
  end

  @doc """
  Generates the view module atom.
  """
  @spec build_view_module(module(), module() | nil) :: module()
  def build_view_module(module, nil), do: module
  def build_view_module(module, web_module) when is_atom(web_module) do
    build_view_module(module, split_module(web_module))
  end
  def build_view_module(module, base) do
    base = pow_base(module, base)

    module
    |> split_module()
    |> build_module(base)
  end

  defp pow_base(module, base) do
    [pow_module | _rest] = Module.split(module)

    base ++ [pow_module]
  end

  defp build_layout({view, template}, web_module) when is_atom(web_module) do
    build_layout({view, template}, split_module(web_module))
  end
  defp build_layout({view, template}, base) do
    view =
      view
      |> split_module()
      |> build_module(base)

    {view, template}
  end

  defp build_module([_base, "Phoenix" | rest], base) do
    base
    |> Enum.concat(rest)
    |> Module.concat()
  end

  defp split_module(nil), do: nil
  defp split_module(module) when is_atom(module), do: Module.split(module)
end
