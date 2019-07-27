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

    title = html.at_css("#workskin h2.heading").content
    author = html.at_css("#workskin a[rel=author]").content

    xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8')
    xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do
      xml.title title
      xml.author { xml.name author }
      xml.id generate_iri(path)

      ### FIXME should this link to the entire work?
      xml.link rel: "alternate", type: "text/html", href: uri

      updated = DateTime.new(year=0)
      chapters = html.css("#chapters > .chapter").map do |chapter|
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
  title_node = chapter.at_css("> div[role=complementary] > h3.title")
  a_node = title_node.at_css("> a")

  title = title_node.content.split(": ", 2)[1].strip

  # note: URI("file:///foo/bar").merge("/baz").to_s == "file:///baz"
  chapter_uri = uri.merge(a_node[:href]).to_s

  {
    title: title,
    id: generate_iri(a_node[:href]),
    link: { rel: "alternate", type: "text/html", href: chapter_uri },
    ### FIXME date isn’t available in entire work view
    date: DateTime.new(year=0, month=1, day=1),
    # date: DateTime.parse(chapter.at_css("> span.datetime").content.delete "()"),
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
