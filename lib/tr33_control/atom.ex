defmodule Tr33Control.Atom do
  use Ecto.Type

  def type, do: :string

  def cast(string) when is_binary(string) do
    {:ok, String.to_atom(string)}
  end

  def cast(atom) when is_atom(atom) do
    {:ok, atom}
  end

  def load(string) when is_binary(string) do
    {:ok, String.to_atom(string)}
  end

  def dump(atom) when is_atom(atom) do
    {:ok, Atom.to_string(atom)}
  end
end
