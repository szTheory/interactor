defmodule Interactor do
  use Behaviour
  alias Interactor.Interaction

  @moduledoc """
  A tool for modeling events that happen in your application.

  #TODO: Docs, Examples, WHY

  """

  @type opts :: binary | tuple | atom | integer | float | [opts] | %{opts => opts}

  @doc """
  Primary interactor callback.

  #TODO: Docs, Examples, explain return values and assign_to

  """
  @callback call(Interaction.t, opts) :: Interaction.t | {:ok, any} | {:error, any} | any

  @doc """
  Call an Interactor.

  #TODO: Docs, Examples

  """
  @spec call(module | {module, atom}, Interaction.t | map, Keyword.t) :: Interaction.t
  def call(interactor, interaction, opts \\ [])
  def call({module, fun}, %Interaction{} = interaction, opts),
    do: do_call(module, fun, interaction, opts[:strategy], opts)
  def call(module, %Interaction{} = i, opts),
    do: call({module, :call}, i, opts)
  def call(interactor, assigns, opts),
    do: call(interactor, %Interaction{assigns: assigns}, opts)

  defp do_call(module, fun, interaction, :sync, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Sync, opts)
  defp do_call(module, fun, interaction, nil, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Sync, opts)
  defp do_call(module, fun, interaction, :async, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Async, opts)
  defp do_call(module, fun, interaction, :task, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Task, opts)
  defp do_call(module, fun, interaction, strategy, opts) do
    assign_to = determine_assign_to(module, fun, opts[:assign_to])
    case strategy.execute(module, fun, interaction, opts) do
      # When interaction is returned do nothing
      %Interaction{} = interaction -> interaction
      # Otherwise properly add result to interaction
      {:error, error} -> %{interaction | success: false, error: error}
      {:ok, other} -> Interaction.assign(interaction, assign_to, other)
      other -> Interaction.assign(interaction, assign_to, other)
    end
  end

  defp determine_assign_to(module, :call, nil) do
    module
    |> Atom.to_string
    |> String.split(".")
    |> Enum.reverse
    |> hd
    |> Macro.underscore
    |> String.to_atom
  end
  defp determine_assign_to(_module, fun, nil), do: fun
  defp determine_assign_to(_module, _fun, assign_to), do: assign_to
end
