defmodule Incunabula.Reconcile do
  @moduledoc """
  This builds a review by doing a fuzzy match on the two text's ASTs

  The first match identifies which components have the same hash -
  and are identicial

  The second match tries to identify moved components

  The third match tries to match actual paragraphs
  """

  @percentagetrigger 20

  @annotations [
    %{delete:   %{before: "<span class='deleted'>",
                  after:  "</span>"}},
    %{insert:   %{before: "<span class='inserted'>",
                  after:  "</span>"}},
    %{modified: %{before: "<span class='modified'>",
                  after:  "</span>"}}
  ]

  def reconcile(slug, original, review) do
    bookdir = Incunabula.Git.get_book_dir(slug)
    tags = IncunabulaUtilities.DB.getDB(bookdir, "optional_tags.db")
    originalAST = :eiderdown_reconcile.make_reviewable(original, tags)
    reviewAST   = :eiderdown_reconcile.make_reviewable(review, tags)
    {firstoriginal, firstreview} = firstmatch(originalAST, reviewAST)
    {secondoriginal, secondreview} = secondmatch(firstoriginal, firstreview, [], [])
    prettyprint secondreview
    {thirdoriginal, thirdreview} = thirdmatch(secondoriginal, secondreview, [], [])
    formatfn = fn({type, record}) ->
      %{content: content} = record
      case type do
        :no_match  -> Enum.join(["<span class='deleted'>", content, "</span>"])
        :moved     -> Enum.join(["<span class='moved'>",   content, "</span>"])
        :unchanged -> Enum.join(["<p>", content, "</p>"])
        :match     -> Enum.join(["<p>", content, "</p>"])
      end
    end
    _output = for t <- thirdreview, do: formatfn.(t)
  end

  defp thirdmatch([], review, oacc, racc) do
    {Enum.reverse(oacc), Enum.reverse(racc) ++ review}
  end

  defp thirdmatch(original, [], oacc, racc) do
    {Enum.reverse(oacc) ++ original, Enum.reverse(racc)}
  end

  defp thirdmatch([{:no_match, no_match1} = h1 | t1],
    [{:no_match, no_match2} = h2 | t2], oacc, racc) do
    case make_diff(no_match1, no_match2) do
      {:diff, new_content} ->
        newrecord = %{no_match2 | content: new_content}
        thirdmatch(t1, t2, [h1 | oacc], [{:match, newrecord} | racc])
      :no_match            ->
        thirdmatch(t1, t2, [h1 | oacc], [h2 | racc])
    end
  end

  defp thirdmatch([h1 | t1], [h2 | t2], oacc, racc) do
    thirdmatch(t1, t2, [h1 | oacc], [h2 | racc])
  end

  defp make_diff(%{:content => c1}, %{:content => c2}) do
    make_diff2(to_string(c1), to_string(c2))
  end

  # break out for command line testing
  def make_diff2(c1, c2) do
    length1 = String.length(c1)
    length2 = String.length(c2)
    percentage = trunc((length1/length2)*100)
    diff = Diff.diff(c1, c2)
    no_of_changes = length(diff)
    percentagechanges = trunc((no_of_changes/length1)*100)
    newc2 = Diff.annotated_patch(c1, diff, @annotations, &Enum.join/1)
    cond do
      percentagechanges < 20 -> {:diff, newc2}
      true                   -> :no_match
    end
  end

  defp secondmatch([], review, oacc, racc) do
    {Enum.reverse(oacc), Enum.reverse(racc) ++ review}
  end

  defp secondmatch(original, [], oacc, racc) do
    {Enum.reverse(oacc) ++ original, Enum.reverse(racc)}
  end

  # in this clause the matched hash's match so it is a good match not a move
  defp secondmatch([{:unchanged, %{:hash => hash}} = h1 | t1],
    [{:unchanged, %{:hash => hash}} = h2 | t2], oacc, racc) do
    secondmatch(t1, t2, [h1 | oacc], [h2 | racc])
  end

  # in this clause the matches are out of order
  # so mark the review version as 'moved'
  # but we now that the first one matches so we have to search ahead
  # where that matches and mark that one as moved as well
  defp secondmatch([{:unchanged, unchanged} = h1 | t1],
    [{:unchanged, _} = h2 | t2], oacc, racc) do
    {_, %{:hash => hash}} = h1
    newt2 = mark_moved(t2, hash, [])
    secondmatch(t1, [h2 | newt2], [{:moved, unchanged} | oacc], racc)
  end

    defp secondmatch([{:no_match, _} = h1 | t1],
    [{:no_match, _} = h2 | t2], oacc, racc) do
    secondmatch(t1, t2, [h1 | oacc], [h2 | racc])
  end

  # from now on in we chuck away the original record
  defp secondmatch([h1 | t1], review, oacc, racc) do
    secondmatch(t1, review, [h1 | oacc], racc)
  end

  defp mark_moved([{:unchanged, %{:hash => hash} = ast} | t], hash, acc) do
    Enum.reverse(acc) ++ [{:moved, ast} | t]
  end

  defp mark_moved([h | t], hash, acc) do
    mark_moved(t, hash, [h | acc])
  end

  defp firstmatch(original, review) do
    firstmatch2(original, review, [])
  end

  defp firstmatch2([], review, acc) do
    newreview = for r <- review do
      case r do
        {:unchanged, _} -> r
        _               -> {:no_match, r}
      end
    end
    {Enum.reverse(acc), newreview}
  end

  defp firstmatch2([h | t], review, acc) do
    case hash_matches(h, review) do
      true ->
        newreview = mark_review_matched(h, review)
        firstmatch2(t, newreview, [{:unchanged, h} | acc])
      false ->
        firstmatch2(t, review, [{:no_match, h} | acc])
    end
  end

  defp hash_matches(%{:hash => hash}, list) do
    hash_m2(list, hash)
  end

  defp hash_m2([], _hash) do
    false
  end

  defp hash_m2([{:unchanged, _} | t], hash) do
    hash_m2(t, hash)
  end

  defp hash_m2([h | t], hash) do
    case Map.get(h, :hash) do
      ^hash -> true
      _     -> hash_m2(t, hash)
    end
  end

  defp mark_review_matched(%{:hash => hash}, list) do
    mark_matched2(list, hash, [])
  end

  defp mark_matched2([], _hash, acc) do
    Enum.reverse(acc)
  end

  defp mark_matched2([{:unchanged, _} = h | t], hash, acc) do
    mark_matched2(t, hash, [h | acc])
  end

  defp mark_matched2([h | t], hash, acc) do
    case Map.get(h, :hash) do
      ^hash -> mark_matched2(t, hash, [{:unchanged, h} | acc])
      _     -> mark_matched2(t, hash, [h | acc])
    end
  end

  #
  # Testing
  #

  def test() do
    slug = "these-island---a-study-in-two-nationalisms"
    original =
      """
      # Introduction

      Now is the winter of our discontent,
      made glorious summer by this son of York
      ya bas

      Now is the time for all good men
      to come to the aid of the party
      """
    review =
    """
      # Introduction

      Now is the winter of our disco tent,
      made glorious summer by this son of York

      Now is the time for all good men
      to come to the aid of the party
      ya bas
      """
    reconcile(slug, original, review)
  end

  defp prettyprint(list) do
    for {type, map} <- list do
      content = Map.get(map, :content)
      IO.inspect pad(Atom.to_string(type)) <> to_string(content)
    end
  end

  defp pad(string) do
    length = String.length(string)
    pad = String.duplicate(" ", 12 - length)
    string <> pad
  end

end
