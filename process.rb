#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'


# Called on each element of ARGV
def handle_index(path)
  open(path) do |source|
    html = Nokogiri::HTML.parse(source)

    title = html.at_css("#main h2.heading > a").content
    author = html.at_css("a[rel=author]").content
    puts "“#{title}” by #{author}"

    html.css("ol[role=navigation] > li").each do |chapter|
      name = chapter.at_css("> a").content.split(" ", 2)[1]
      date = chapter.at_css("> span.datetime").content

      printf "  %-50s  %s\n", name, date
    end
  end
end


ARGV.each do |path|
  handle_index(path)
end
