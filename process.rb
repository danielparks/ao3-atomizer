#!/usr/bin/env ruby

require 'date'
require 'nokogiri'
require 'open-uri'
require 'uri'

# Called on each element of ARGV
def handle_index(path)
  uri = normalize_argument(path)
  atom_uri = "https://atomizer.demon.horse/archiveofourown.org#{uri.path}.atom"
  entire_work_path = path + "/?view_adult=true&view_full_work=true"

  open(entire_work_path) do |source|
    html = Nokogiri::HTML.parse(source)

    title_node = html.at_css("#workskin h2.heading")
    raise "could not find work title" if title_node == nil
    title = title_node.content.strip

    author_node = html.at_css("#workskin a[rel=author]")
    raise "could not find work author" if author_node == nil
    author = author_node.content.strip

    xml = Nokogiri::XML::Builder.new(:encoding => 'UTF-8')
    xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do
      xml.title title
      xml.author { xml.name author }
      xml.id generate_iri(path)
      xml.link rel: "self", type: "application/atom+xml", href: atom_uri
      xml.link rel: "alternate", type: "text/html", href: uri

      chapters = html.css("#chapters > .chapter").map do |chapter|
        process_chapter uri, xml, chapter
      end

      work_updated = update_dates(path, chapters)
      xml.updated work_updated.xmlschema(0)

      chapters.each do |chapter|
        xml.entry do
          xml.title chapter[:title]
          xml.id chapter[:id]
          xml.link **chapter[:link]
          xml.published chapter[:date].xmlschema(0)
          xml.content type: "html" do
            xml.cdata chapter[:content]
          end
        end
      end
    end

    puts xml.to_xml
  end
end

def process_chapter(uri, xml, chapter)
  title_node = chapter.at_css("> div[role=complementary] > h3.title")
  a_node = title_node.at_css("> a")

  raise "could not find chapter title node" if title_node == nil
  raise "could not find link in chapter title node" if a_node == nil

  title = title_node.content.split(": ", 2).last.strip
  content = chapter.at_css("div[role=article]")

  raise "could not find chapter content" if content == nil

  # Strip landmark nodes that are supposed to be hidden.
  content.css(".landmark").each do |node|
    node.replace("")
  end

  # note: URI("file:///foo/bar").merge("/baz").to_s == "file:///baz"
  chapter_uri = uri.merge(a_node[:href]).to_s

  {
    title: title,
    id: generate_iri(a_node[:href]),
    link: { rel: "alternate", type: "text/html", href: chapter_uri },
    # date isn’t available in entire work view, so leave it empty.
    date: DateTime.new(year=0, month=1, day=1),
    content: content.inner_html,
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
  uri = URI(uri)
  "https://atomizer.demon.horse/archiveofourown.org#{uri.path}"
end

def update_dates(path, chapters)
  work_updated = DateTime.new(year=0)
  i = 0

  open(path + "/navigate") do |source|
    html = Nokogiri::HTML.parse(source)
    html.css("ol[role=navigation] > li > span.datetime").map do |date_node|
      date = DateTime.parse(date_node.content.delete("()"))
      chapters[i][:date] = date

      if work_updated < date
        work_updated = date
      end

      i += 1
    end
  end

  work_updated
end


ARGV.each do |path|
  handle_index(path)
end
