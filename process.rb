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
      xml.id generate_iri(path)
      xml.link rel: "alternate", type: "text/html", href: uri

      updated = DateTime.new(year=0)
      chapters = html.css("ol[role=navigation] > li").map do |chapter|
        obj = process_chapter uri, xml, chapter
        if updated < obj[:date]
          updated = obj[:date]
        end
        obj
      end

      xml.updated updated.xmlschema(0)

      chapters.each do |chapter|
        xml.entry do
          xml.title chapter[:title]
          xml.id chapter[:id]
          xml.link **chapter[:link]
          xml.published chapter[:date].xmlschema(0)
        end
      end
    end

    puts xml.to_xml
  end
end

def process_chapter(uri, xml, chapter)
  # note: URI("file:///foo/bar").merge("/baz").to_s == "file:///baz"
  a = chapter.at_css("> a")
  chapter_uri = uri.merge(a[:href]).to_s

  {
    title: a.content.split(" ", 2)[1],
    id: generate_iri(a[:href]),
    link: { rel: "alternate", type: "text/html", href: chapter_uri },
    date: DateTime.parse(chapter.at_css("> span.datetime").content.delete "()"),
  }
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

def generate_iri(uri)
  ### FIXME: this needs to be a valid IRI (RFC-3987), which allows different
  ### characters than a URI. Also, hard coding a domain smells.
  "https://atomizer.demon.horse/archiveofourown.org#{uri}"
end


ARGV.each do |path|
  handle_index(path)
end
