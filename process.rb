#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'


# Called on each element of ARGV
def handle_index(path)
  open(path) do |source|
    html = Nokogiri::HTML.parse(source)

    title = html.at_css("#main h2.heading > a").content
    author = html.at_css("a[rel=author]").content


    xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8')
    xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do
      xml.title title

      html.css("ol[role=navigation] > li").each do |chapter|
        process_chapter xml, chapter
      end
    end

    puts xml.to_xml
  end
end

def process_chapter(xml, chapter)
  link = chapter.at_css("> a")
  title = link.content.split(" ", 2)[1]
  date = chapter.at_css("> span.datetime").content

  xml.entry do
    xml.title title
    xml.link rel: "alternate", href: link[:href]
  end
end


ARGV.each do |path|
  handle_index(path)
end
