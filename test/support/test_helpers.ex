defmodule Hexpm.TestHelpers do
   @tmp Application.get_env(:hexpm, :tmp_dir)

  def create_tar(meta, files) do
    meta =
      meta
      |> Map.put_new(:app, meta[:name])
      |> Map.put_new(:build_tools, ["mix"])
      |> Map.put_new(:files, [])
      |> Map.put_new(:licenses, ["Apache"])
      |> Map.put_new(:requirements, %{})

    contents_path = Path.join(@tmp, "#{meta[:name]}-#{meta[:version]}-contents.tar.gz")
    files = Enum.map(files, fn {name, bin} -> {String.to_charlist(name), bin} end)
    :ok = :erl_tar.create(contents_path, files, [:compressed])
    contents = File.read!(contents_path)

    meta_string = Hexpm.Web.ConsultFormat.encode(meta)
    blob = "3" <> meta_string <> contents
    checksum = :crypto.hash(:sha256, blob) |> Base.encode16

    files = [
      {'VERSION', "3"},
      {'CHECKSUM', checksum},
      {'metadata.config', meta_string},
      {'contents.tar.gz', contents}]
    path = Path.join(@tmp, "#{meta[:name]}-#{meta[:version]}.tar")
    :ok = :erl_tar.create(path, files)

    File.read!(path)
  end

  def rel_meta(params) do
    meta =
      params
      |> Map.put_new(:build_tools, ["mix"])
      |> Map.update(:requirements, [], &requirements_meta/1)
    Map.put(params, :meta, meta)
  end

  def pkg_meta(params) do
    meta = Map.put_new(params, :licenses, ["Apache"])
    Map.put(params, :meta, meta)
  end

  defp requirements_meta(list) do
    Enum.map(list, fn req ->
      req
      |> Map.put_new("optional", false)
      |> Map.put_new("app", req["name"])
    end)
  end
end
