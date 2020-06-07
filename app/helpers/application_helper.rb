module ApplicationHelper
  def nav_link(link_text, link_path, *args)
    class_name = (request.env['PATH_INFO'].include? link_path) ? 'current' : nil

    content_tag(:div, :class => class_name) do
      link_to link_text, link_path, *args
    end
  end
end
