defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias PhoenixTest.Html
  alias PhoenixTest.Query

  def assert_has(session, "title", text) do
    title = PhoenixTest.Driver.render_page_title(session)

    if title == text do
      assert true
    else
      raise AssertionError,
        message: """
        Expected title to be #{inspect(text)} but got #{inspect(title)}
        """
    end
  end

  def assert_has(session_or_element, selector, text) do
    session_or_element
    |> render_html()
    |> Query.find(selector, text)
    |> case do
      {:found, _found} ->
        assert true

      {:found_many, _found} ->
        assert true

      {:not_found, []} ->
        raise AssertionError,
          message: """
          Could not find any elements with selector #{inspect(selector)}.
          """

      {:not_found, elements_matched_selector} ->
        raise AssertionError,
          message: """
          Could not find element with text #{inspect(text)}.

          Found other elements matching the selector #{inspect(selector)}:

          #{format_found_elements(elements_matched_selector)}
          """
    end

    session_or_element
  end

  def refute_has(session, "title", text) do
    title = PhoenixTest.Driver.render_page_title(session)

    if title == text do
      raise AssertionError,
        message: """
        Expected title not to be #{inspect(text)}
        """
    else
      refute false
    end
  end

  def refute_has(session, selector, text) do
    session
    |> render_html()
    |> Query.find(selector, text)
    |> case do
      {:not_found, _} ->
        refute false

      {:found, element} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found an element with selector #{inspect(selector)} and text #{inspect(text)}:

          #{format_found_elements(element)}
          """

      {:found_many, elements} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found #{Enum.count(elements)} elements with selector #{inspect(selector)} and text #{inspect(text)}:
          """
    end

    session
  end

  def within(session, selector, fun) do
    session
    |> render_html()
    |> Query.find(selector)
    |> case do
      {:found, element} ->
        fun.(element)

      :not_found ->
        raise "Helpful error message"
    end
  end

  defp render_html(session) when is_struct(session) do
    PhoenixTest.Driver.render_html(session)
  end

  defp render_html(element) do
    Floki.raw_html(element)
  end

  defp format_found_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &Html.raw/1)
  end

  defp format_found_elements(element), do: format_found_elements([element])
end
