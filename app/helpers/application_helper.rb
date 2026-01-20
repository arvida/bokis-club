module ApplicationHelper
  def format_book_description(description)
    return "" if description.blank?

    html = sanitize(description)

    # Match quotes like: "quote text" Attribution
    # Handles both regular quotes and unicode quotes
    html.gsub!(/[""]([^""]+)[""](\s+[\p{Lu}][\p{L}\s]+)(?=<|\z)/u) do |_match|
      quote_text = ::Regexp.last_match(1)
      attribution = ::Regexp.last_match(2).strip
      <<~HTML.html_safe
        <blockquote class="border-l-2 border-vermillion/30 pl-4 my-4 italic text-ink-muted">
          <p>"#{quote_text}"</p>
          <cite class="block mt-2 text-sm not-italic text-ink-subtle">— #{attribution}</cite>
        </blockquote>
      HTML
    end

    html.html_safe
  end

  DOCK_ICONS = {
    home: '<svg xmlns="http://www.w3.org/2000/svg" class="w-full h-full" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>',
    calendar: '<svg xmlns="http://www.w3.org/2000/svg" class="w-full h-full" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
    chat: '<svg xmlns="http://www.w3.org/2000/svg" class="w-full h-full" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>',
    user: '<svg xmlns="http://www.w3.org/2000/svg" class="w-full h-full" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>'
  }.freeze

  def dock_link(label, path, icon:)
    is_active = current_page?(path)
    classes = [
      "flex flex-col items-center justify-center gap-1 min-w-[60px] py-2 transition-colors",
      is_active ? "text-vermillion" : "text-cream hover:text-white"
    ].join(" ")

    link_to path, class: classes, "aria-current": (is_active ? "page" : nil) do
      content_tag(:span, DOCK_ICONS[icon].html_safe, class: "inline-flex items-center justify-center w-6 h-6", aria: { hidden: true }) +
        content_tag(:span, label, class: "text-xs font-medium")
    end
  end

  def dom_id_for_item(item)
    "discussion-item-#{item['id']}"
  end

  def render_with_mentions(content, club)
    return "" if content.blank?

    member_names = club.members.pluck(:name).map(&:downcase)

    escaped_content = h(content)
    escaped_content.gsub(/@(\w+)/i) do |match|
      name = ::Regexp.last_match(1).downcase
      if member_names.include?(name)
        "<span class=\"text-vermillion font-medium\">#{match}</span>"
      else
        match
      end
    end.html_safe
  end
end
