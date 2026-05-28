module MessagesHelper
  def render_markdown(content)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, { autolink: true, tables: true, fenced_code_blocks: true })
    markdown.render(content)
  end
end
