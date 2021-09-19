module ApplicationHelper
  def nav_link(link_text, link_path, *args)
    class_name = (request.env['PATH_INFO'].include? link_path) ? 'current' : nil

    content_tag(:div, :class => class_name) do
      link_to link_text, link_path, *args
    end
  end
  
  def default_meta_description
    "LiveLCA is a platform for all people to get a view into their daily CO2 spendings. The platform provides data on food in various food groups and the database keeps growing. You can use LiveLCA to calculate the CO2 emissions from recipes, settle disputes with your friends or simply as a reference work."
  end
end
