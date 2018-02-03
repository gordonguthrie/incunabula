defmodule Incunabula.Controller do
  alias Incunabula.User

  defmacro __using__(_) do
    quote do
      def action(conn, _), do: Incunabula.Controller.__action__(__MODULE__, conn)
      defoverridable action: 2
    end
  end

  def __action__(controller, conn) do
    guest_user = %User{username: nil}
    args = [conn, conn.params, conn.assigns[:current_user] || guest_user]
    apply(controller, Phoenix.Controller.action_name(conn), args)
  end
end
