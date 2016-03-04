defmodule RamlParser.YamerlIncludeNodeTest do
	use ExUnit.Case
	alias RamlParser.YamerlIncludeNode, as: YIN
	require YIN
	require Record

	records = Record.extract_all(from_lib: "yamerl/include/yamerl_nodes.hrl")
	for {name, fields} <- records do
		Record.defrecordp name, fields
	end
	
	test "simple string" do
		str = """
    #%RAML 0.8
		---
		prop: !include test
    """
		[doc] = :yamerl_constr.string(str, node_mods: [YIN], detailed_constr: true)
		text =
			doc
  		|> yamerl_doc(:root)
			|> yamerl_map(:pairs)
			|> Enum.at(0)
			|> elem(1)
			|> YIN.raml_include(:file)
		assert text == 'test'
	end

	test "absolute file name" do
		str = """
		#%RAML 0.8
    ---
		prop: !include /absolute/path-to/file.yaml
    """
    [doc] = :yamerl_constr.string(str, node_mods: [YIN], detailed_constr: true)
		text =
			doc
  		|> yamerl_doc(:root)
			|> yamerl_map(:pairs)
			|> Enum.at(0)
			|> elem(1)
			|> YIN.raml_include(:file)
		assert text == '/absolute/path-to/file.yaml'
	end

	test "relative file name" do
		str = """
		#%RAML 0.8
		---
		prop: !include ../../relative/file-name.raml
    """
		[doc] = :yamerl_constr.string(str, node_mods: [YIN], detailed_constr: true)
		text =
			doc
		  |> yamerl_doc(:root)
			|> yamerl_map(:pairs)
			|> Enum.at(0)
			|> elem(1)
			|> YIN.raml_include(:file)
		assert text == '../../relative/file-name.raml'
	end

	test "complicated structure" do
		str = """
    #%RAML 0.8
    ---
    prop:
      - a: 0
        b: 1
      - c: !include test
        d: 2
		"""
		[doc] = :yamerl_constr.string(str, node_mods: [YIN], detailed_constr: true)
		text =
			doc
		  |> yamerl_doc(:root)
			|> yamerl_map(:pairs)
			|> Enum.at(0)
			|> elem(1)
			|> yamerl_seq(:entries)
			|> Enum.at(1)
			|> yamerl_map(:pairs)
			|> Enum.at(0)
			|> elem(1)
			|> YIN.raml_include(:file)
		assert text == 'test'
	end
end
