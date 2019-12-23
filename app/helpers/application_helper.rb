module ApplicationHelper
  def nav_link(link_text, link_path, *args)
    begin
      recognized = Rails.application.routes.recognize_path(link_path)
    rescue
      recognized = {:controller => ""}
    end
    class_name = recognized[:controller] == params[:controller] ? 'current' : nil

    content_tag(:div, :class => class_name) do
      link_to link_text, link_path, *args
    end
  end
end
