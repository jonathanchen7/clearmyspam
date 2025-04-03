require "nokogiri"

class SitemapController < ApplicationController
  def index
    xml = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
        # Static pages
        add_static_page(xml, root_url, "1.0", "home")
        add_static_page(xml, faq_url, "0.8", "faq")
        add_static_page(xml, pricing_url, "0.8", "pricing")
        add_static_page(xml, privacy_url, "0.5", "privacy")
        add_static_page(xml, terms_url, "0.5", "terms")

        # Blog posts
        Dir.glob(Rails.root.join("app", "views", "blogs", "*.md")).each do |file|
          filename = File.basename(file, ".md")
          xml.url do
            xml.loc blogs_show_url(slug: filename)
            xml.priority "0.7"
            xml.lastmod File.mtime(file).iso8601
          end
        end
      end
    end

    render xml: xml.to_xml
  end

  private

  def add_static_page(xml, url, priority, page_name)
    xml.url do
      xml.loc url
      xml.priority priority
      xml.lastmod get_page_timestamp(page_name).iso8601
    end
  end

  def get_page_timestamp(page_name)
    view_dir = Rails.root.join("app", "views", page_name.to_s)
    controller_path = Rails.root.join("app", "controllers", "#{page_name}_controller.rb")

    timestamps = []

    # Check all files in the views directory if it exists
    if Dir.exist?(view_dir)
      Dir.glob("#{view_dir}/**/*").each do |path|
        timestamps << File.mtime(path) if File.file?(path)
      end
    end

    # Add controller timestamp if it exists
    timestamps << File.mtime(controller_path) if File.exist?(controller_path)

    timestamps.max || Date.new(2025, 4, 1)
  end
end
