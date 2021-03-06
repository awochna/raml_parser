defmodule RamlParser.YamerlIncludeNode do
	@moduledoc """
	Implements a parser for !include tags in RAML. 
	"""

	require Record
	require Logger
	
  Record.defrecordp :yamerl_constr,
  	Record.extract(:yamerl_constr,
									 from_lib: "yamerl/include/internal/yamerl_constr.hrl")
	Record.defrecordp :yamerl_scalar,
		Record.extract(:yamerl_scalar,
									 from_lib: "yamerl/include/yamerl_tokens.hrl")
	Record.defrecordp :yamerl_str,
    Record.extract(:yamerl_str,
									 from_lib: "yamerl/include/yamerl_nodes.hrl")
	Record.defrecordp :yamerl_parsing_error,
  	Record.extract(:yamerl_parsing_error,
									 from_lib: "yamerl/include/yamerl_errors.hrl")

	Record.defrecord :raml_include, [module: :undefined, tag: '!', pres: [], file: :undefined]
  
	@tag '!include'

	@doc """
	Returns a list of tags the module can parse (just !include)
  """
	@spec tags :: [String.t]
	def tags do
    [@tag]
	end

	@doc """ 
  Creates the actual token yamerl uses to make the yaml data
	object. Although RAML specifies that included files need to be
	parsed, we leave that up to the module that actually reads and
	includes the file. Here we're just making a note that a file should
	be fetched.
  """
	@spec construct_token(tuple, atom, tuple) :: tuple
	def construct_token(constr, :undefined, token) do
    details = yamerl_constr(constr, :detailed_constr)
		construct_token(details, token)
	end

	def construct_token(_const, _node, token) do
		error = yamerl_parsing_error(name: :not_a_file,
																 token: token,
																 text: "Invalid file name",
																 line: yamerl_scalar(token, :line),
																 column: yamerl_scalar(token, :column))
		throw(error)
	end

	def construct_token(false, token) do
		text = yamerl_scalar(token, :text)
		{:finished, text}
	end

	def construct_token(true, token) do
		text = yamerl_scalar(token, :text)
		pres = :yamerl_constr.get_pres_details(token)
		node = raml_include(module: __MODULE__,
												tag: @tag,
												pres: pres,
												file: text)
		{:finished, node}
	end
	
	@doc """
  This is the location in the file of the node? I think? This seems to work though.
  """
	def node_pres(node) do
    yamerl_str(node, :pres)
	end
end
