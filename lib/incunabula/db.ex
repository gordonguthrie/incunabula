defmodule Incunabula.DB do

  @acc []

  @moduledoc """
  A primitive database handler
  All records are maps
  You are expected to validate that records and keys coming in are valid
  before using it
  Everything is hoyed onto storage as a list of terms delimited by a '.'
  All reads are via 'File.consult/1'
  All manipulation is done in memory
  The database sizes are bounded by
  * the number of chapters in a book
  * the numbers of reviews in a review cycle
  * the number of chaffs created
  * if any of these get > 100 I would be very surprised
  The databases here are all designed to be stored under git - hence the format
  """

  def getDB(dir, file) do
    readDB(dir, file)
  end

  def createDB(dir, file) do
    writeDB(dir, file, [])
  end

  def appendDB(dir, file, newrecord) do
    old = readDB(dir, file)
    new = old ++ [newrecord]
    writeDB(dir, file, new)
  end

  def update_value(dir, file, keyfield, keyval, valfield, newval) do
    db = readDB(dir, file)
    case update(db, {:field, {valfield, newval}}, keyfield, keyval, @acc) do
      {:error, error} -> exit(error)
      newdb           -> writeDB(dir, file, newdb)
    end
  end

  def update_record(dir, file, keyfield, keyval, newrecord) do
    db = readDB(dir, file)
    case update(db, {:record, newrecord}, keyfield, keyval, @acc) do
      {:error, error} -> exit(error)
      newdb           -> writeDB(dir, file, newdb)
    end
  end

  def lookup_value(dir, file, keyfield, keyvalue, valuefield) do
    db = readDB(dir, file)
    _record = filter(db, {:field, valuefield}, keyfield, keyvalue)
  end

  def lookup_record(dir, file, keyfield, keyvalue) do
    db = readDB(dir, file)
    _record = filter(db, :record, keyfield, keyvalue)
  end

  defp readDB(dir, file) do
    path = Path.join(dir, file)
    {:ok, terms} = :file.consult(path)
    terms
  end

  defp update([], _type, _fieldname, _fieldvalue, acc) do
    Enum.reverse(acc)
  end

  defp update([h | t], type, fieldname, fieldvalue, acc) do
    newacc = case Map.has_key?(h, fieldname) do
               false -> exit(:non_existant_fetch_key)
               true ->  case Map.get(h, fieldname) do
                          ^fieldvalue -> modify_record(h, type)
                          _           -> h
                        end
             end
    update(t, type, fieldname, fieldvalue, [newacc | acc])
  end

  defp modify_record(_, {:record, newrecord}) do
    newrecord
  end

  defp modify_record(record, {:field, {fieldname, newvalue}}) do
    case Map.has_key?(record, fieldname) do
      false -> exit(:non_existant_update_key)
      true  -> Map.put(record, fieldname, newvalue)
    end
  end

  defp filter([], _, _, _) do
    exit(:no_match_of_key)
  end

  defp filter([h | t], returntype, fieldname, fieldvalue) do
    case Map.has_key?(h, fieldname) do
      false -> exit(:non_existant_fetch_key)
      true ->  case Map.get(h, fieldname) do
                 fieldvalue -> get_return(returntype, h)
                 _          -> filter(t, returntype, fieldname, fieldvalue)
               end
    end
  end

  defp get_return(:record, h), do: h

  defp get_return({:field, fieldname}, h) do
    case Map.has_key?(h, fieldname) do
      false -> exit(:non_existant_get_key)
      true  -> Map.get(h, fieldname)
    end
  end

  defp writeDB(dir, file, terms) when is_list(terms) do
    path = Path.join(dir, file)
    contents = for t <- terms, do: :io_lib.format("~p.~n", [t])
    :ok = File.write(path, contents)
  end

end
