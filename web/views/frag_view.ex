defmodule Incunabula.FragView do
  use Incunabula.Web, :view

  def make_review_control("in review") do
    """
    <button class='ui labeled icon basic right floated fluid mini button' data-next='in reconciliation'>
    <i class='arrow right icon'></i>
    in review
    </button>
    """
  end

  def make_review_control("in reconciliation") do
    """
    <button class='ui labeled icon basic right floated fluid  mini button' data-next='reconcile'>
    <i class='arrow right icon'></i>
    in reconciliation
    </button>
    """
  end

  def make_review_control("closed") do
    """
    <button class='circular ui disabled basic right floated mini icon button'>
    <i class='lock icon'></i>
    </button>
    """
  end

  def make_review_link(slug, review_slug, review_title, "in review") do
    "<a href='/books/" <>
      slug             <>
      "/reviews/"      <>
      review_slug      <>
      "'>"             <>
      review_title     <>
      "</a>"
  end

  def make_review_link(slug, review_slug, review_title, "in reconciliation") do
    "<a href='/books/"  <>
      slug              <>
      "/reviews/"       <>
      review_slug       <>
      "/reconciliation" <>
      "'>"              <>
      review_title      <>
      "</a>"
  end

  def make_review_link(slug, review_slug, review_title, "closed") do
    "<a href='/books/" <>
      slug             <>
      "/reviews/"      <>
      review_slug      <>
      "/preview"       <>
      "'>"             <>
      review_title     <>
      "</a>"
  end

end
