module ApplicationHelper
  MASK = "•••"
  VISIBLE_HEALTH_NUMBER_CHARACTERS = 3

  def mask_health_number(health_number)
    value = health_number.to_s
    return MASK if value.length <= VISIBLE_HEALTH_NUMBER_CHARACTERS + 1

    "#{MASK}#{value.last(VISIBLE_HEALTH_NUMBER_CHARACTERS)}"
  end

  def format_duration(seconds)
    return "—" if seconds.nil?
    return "#{(seconds * 1000).round} ms" if seconds < 1
    return format("%.1f s", seconds) if seconds < 60

    "#{(seconds / 60).floor} min #{(seconds % 60).round} s"
  end

  def format_percent(value)
    value.nil? ? "—" : "#{value}%"
  end

  def format_time(time)
    time ? l(time, format: "%Y-%m-%d %H:%M:%S") : "—"
  end

  def status_badge(status)
    tag.span(status.humanize, class: "badge badge-#{status}")
  end

  def field_label(field)
    Patient.human_attribute_name(field)
  end

  def in_field_order(hash)
    (hash || {}).sort_by { |field, _| Patient::MIGRATABLE_ATTRIBUTES.index(field.to_s) || Patient::MIGRATABLE_ATTRIBUTES.size }
  end

  def label_for_code(code)
    code.to_s.humanize
  end

  def sorted_counts(counts)
    (counts || {}).sort_by { |key, count| [ -count, key.to_s ] }
  end

  def pagination_links
    return if total_pages <= 1

    tag.nav(class: "pagination") do
      safe_join([
        (link_to("← Previous", url_for(request.query_parameters.merge(page: current_page - 1))) if current_page > 1),
        tag.span("Page #{current_page} of #{total_pages}"),
        (link_to("Next →", url_for(request.query_parameters.merge(page: current_page + 1))) if current_page < total_pages)
      ].compact, " ")
    end
  end
end
