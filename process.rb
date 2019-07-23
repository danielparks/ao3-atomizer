#!/usr/bin/env ruby

require 'date'
require 'nokogiri'
require 'open-uri'
require 'uri'

# Called on each element of ARGV
def handle_index(path)
  uri = normalize_argument(path)

  open(path) do |source|
    html = Nokogiri::HTML.parse(source)

    title = html.at_css("#main h2.heading > a").content
    author = html.at_css("a[rel=author]").content

    xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8')
    xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do
      xml.title title
      xml.author { xml.name author }
      xml.link rel: "alternate", type: "text/html", href: uri

      html.css("ol[role=navigation] > li").each do |chapter|
        process_chapter uri, xml, chapter
      end
    end

    puts xml.to_xml
  end
end

def process_chapter(uri, xml, chapter)
  # note: URI("file:///foo/bar").merge("/baz").to_s == "file:///baz"
  a = chapter.at_css("> a")
  chapter_uri = uri.merge(a[:href]).to_s

  title = a.content.split(" ", 2)[1]
  date =  DateTime.parse(chapter.at_css("> span.datetime").content.delete "()")

  xml.entry do
    xml.title title
    xml.published date.xmlschema(0)
    xml.link rel: "alternate", type: "text/html", href: chapter_uri
  end
end

def normalize_argument(arg)
  uri = URI(arg)
  if uri.scheme == nil
    # uri is a simple path, not a URI
    uri = URI(File.absolute_path(arg))
    uri.scheme = "file"
  end
  uri
end


ARGV.each do |path|
  handle_index(path)
end
