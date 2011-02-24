#!/usr/bin/env ruby

# Script to generate PDF cards suitable for planning poker
# from Pivotal Tracker [http://www.pivotaltracker.com/] CSV export.

# Inspired by Bryan Helmkamp's http://github.com/brynary/features2cards/

# Example output: http://img.skitch.com/20100522-d1kkhfu6yub7gpye97ikfuubi2.png

require 'rubygems'
require 'fastercsv'
require 'ostruct'
require 'term/ansicolor'
require 'prawn'
require 'prawn/layout/grid'
require "rqr"


$: << File.join(File.dirname(__FILE__), 'lib')
require 'card'

class String; include Term::ANSIColor; end

file = ARGV.first

unless file
  puts "[!] Please provide a path to CSV file"
  exit 1
end

cards = Card.read_from_csv(file)

begin

outfile = File.basename(file, ".csv")

Prawn::Document.generate("#{outfile}.pdf",
   :page_layout => :landscape,
   :margin      => [25, 25, 50, 25],
   :page_size   => 'A4') do |pdf|

    @num_cards_on_page = 0

    pdf.font "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"

    cards.each_with_index do |card, i|

      # --- Split pages
      if i > 0 and i % 4 == 0
        # puts "New page..."
        pdf.start_new_page
        @num_cards_on_page  = 1
      else
        @num_cards_on_page += 1
      end

      # --- Define 2x2 grid
      pdf.define_grid(:columns => 2, :rows => 2, :gutter => 42)
      # pdf.grid.show_all

      row    = (@num_cards_on_page+1) / 4
      column = i % 2

      # p @num_cards_on_page
      # p [ row, column ]

      card.generate_pdf(pdf, pdf.grid( row, column ))

    end

    # --- Footer
    pdf.number_pages "#{outfile}.pdf", [pdf.bounds.left,  -28]
    pdf.number_pages "<page>/<total>", [pdf.bounds.right-16, -28]
end

puts ">>> Generated PDF file in '#{outfile}.pdf' with #{cards.size} stories:".black.on_green

cards.each do |card|
  puts "* #{card.title}"
end

rescue Exception
  puts "[!] There was an error while generating the PDF file... What happened was:".white.on_red
  raise
end
