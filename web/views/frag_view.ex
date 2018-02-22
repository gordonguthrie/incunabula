defmodule Incunabula.FragView do
  use Incunabula.Web, :view

  def make_review_control("in review", slug, review_slug) do
    "<button class='incunabula-review-button ui labeled icon basic right floated fluid mini button' data-next='reconcile' data-url='/books/"
    <> slug <> "/reviews/" <> review_slug <> "/changestatus'>" <>
    """
    <i class='arrow right icon'></i>
    in review
    </button>
    """
  end

  def make_review_control("reconcile", slug, review_slug) do
    "<button class='incunabula-review-button ui labeled icon basic right floated fluid  mini button' data-next='closed' data-url='/books/"
    <> slug <> "/reviews/" <> review_slug <> "/changestatus'>" <>
    """
    <i class='arrow right icon'></i>
    ready to reconcile
    </button>
    """
  end

  def make_review_control("closed", slug, review_slug) do
    "<button class='incunabula-review-button ui labeled icon basic right floated fluid  mini button' data-next='in review' data-url='/books/"
    <> slug <> "/reviews/" <> review_slug <> "/changestatus'>" <>
    """
    <i class='lock icon'></i>
    (reopen review)
    </button>
    """
  end

  def make_review_link(slug, review_slug, review_title, "in review", "author") do
    make_preview_link(slug, review_slug, review_title)
  end

  def make_review_link(slug, review_slug, review_title, "in review", "reviewer") do
    make_edit_link(slug, review_slug, review_title)
  end

  def make_review_link(slug, review_slug, review_title, "reconcile", "author") do
    make_reconciliation_link(slug, review_slug, review_title)
  end

  def make_review_link(slug, review_slug, review_title, "reconcile", "reviewer") do
    make_preview_link(slug, review_slug, review_title)
  end

  def make_review_link(slug, review_slug, review_title, "closed", _role) do
    make_preview_link(slug, review_slug, review_title)
  end

  defp make_edit_link(slug, review_slug, review_title) do
    "<a href='/books/" <>
      slug             <>
      "/reviews/"      <>
      review_slug      <>
      "'>"             <>
      review_title     <>
      "</a>&nbsp;<small>(edit)</small>"
  end

  defp make_preview_link(slug, review_slug, review_title) do
    "<a href='/books/" <>
      slug             <>
      "/reviews/"      <>
      review_slug      <>
      "/preview"       <>
      "'>"             <>
      review_title     <>
      "</a>&nbsp;<small>(preview)</small>"
    end

    defp make_reconciliation_link(slug, review_slug, review_title) do
    "<a href='/books/"  <>
      slug              <>
      "/reviews/"       <>
      review_slug       <>
      "/reconciliation" <>
      "'>"              <>
      review_title      <>
      "</a>&nbsp;<small>(reconcile)</small>"
  end

end
