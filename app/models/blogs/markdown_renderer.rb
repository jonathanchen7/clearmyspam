require "redcarpet"

module Blogs
  class MarkdownRenderer < Redcarpet::Render::HTML
    include ActionView::Helpers

    def header(text, header_level)
      text_size = case header_level
                  when 1
                    "text-4xl"
                  when 2
                    "text-2xl"
                  when 3
                    "text-xl"
                  when 4
                    "text-lg"
                  when 5
                    "text-base"
                  else
                    "text-sm"
                  end

      text_color = case header_level
                   when 1, 2
                     "text-primary"
                   else
                     "text-gray-600"
                   end

      text_weight = case header_level
                    when 1, 2
                      "font-semibold"
                    when 6
                      "font-normal"
                    else
                      "font-medium"
                    end

      bottom_margin = case header_level
                      when 1, 2
                        "mb-2"
                      else
                        "mb-1"
                      end

      %(<h#{header_level} class="#{class_names(text_size, text_color, text_weight, bottom_margin, "mt-2")}">#{text}</h#{header_level}>)
    end

    def paragraph(text)
      %(<p class="text-md leading-7 text-gray-700 mb-4">#{text}</p>)
    end

    def link(link, title, content)
      link_to(content, link, class: "font-semibold text-primary underline", title: title)
    end

    def block_quote(quote)
      %(<blockquote class="border-l-4 border-gray-300 pl-4 pr-2 pt-4 pb-1 my-4 bg-gray-200 text-base">#{quote}</blockquote>)
    end

    def list(contents, list_type)
      list_type = list_type == :ordered ? "ol" : "ul"
      %(<#{list_type} class="list-inside list-decimal pl-4 my-4">#{contents}</#{list_type}>)
    end

    def list_item(text, list_type)
      %(<li class="text-md text-gray-700 mb-2">#{text}</li>)
    end

    def image(link, title, alt_text)
      %(
      <div>
        #{image_tag "blogs/#{link}", class: "rounded-lg shadow-lg border", alt: alt_text, title: title}
        <p class="mt-2 mb-4 text-sm text-gray-500">#{title}</p>
      </div>
      )
    end

    def codespan(code)
      %(<code class="text-sm text-gray-700 bg-gray-200 py-1 px-2 rounded-md">#{code}</code>)
    end

    def double_emphasis(text)
      %(<strong class="font-semibold text-primary">#{text}</strong>)
    end

    def hrule
      %(<hr class="border-gray-300 my-4">)
    end
  end
end
