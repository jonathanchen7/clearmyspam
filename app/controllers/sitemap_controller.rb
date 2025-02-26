require "nokogiri"

class SitemapController < ApplicationController
  def index
    xml = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
        xml.url do
          xml.loc root_url
          xml.priority "1.0"
          xml.changefreq "weekly"
        end
        xml.url do
          xml.loc faq_url
          xml.priority "0.8"
          xml.changefreq "monthly"
        end
        xml.url do
          xml.loc pricing_url
          xml.priority "0.8"
          xml.changefreq "monthly"
        end
        xml.url do
          xml.loc privacy_url
          xml.priority "0.5"
          xml.changefreq "yearly"
        end
        xml.url do
          xml.loc terms_url
          xml.priority "0.5"
          xml.changefreq "yearly"
        end

        Dir.glob(Rails.root.join("app", "views", "blogs", "*.md")).each do |file|
          puts file
          filename = File.basename(file, ".md")
          xml.url do
            xml.loc blogs_show_url(slug: filename)
            xml.priority "0.7"
            xml.changefreq "weekly"
            xml.lastmod File.mtime(file).iso8601
          end
        end
      end
    end

    render xml: xml.to_xml
  end
end
