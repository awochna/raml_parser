defmodule RamlParseError do
  defexception [:message]

  def exception(value) do
    %RamlParseError{message: value}
  end
end
