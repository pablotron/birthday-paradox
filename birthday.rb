#!/usr/bin/env ruby

#
# birthday.rb: Write probability that two people in a room full of N
# people share a birthday to a table or as a SVG depending on the 
# first command-line parameter.
#
# This script can operate in two modes:
#
# 1. Generate a table in CSV or YAML format with the number of people
#    in the range [1, 25] with intermediate values [5, 21] elided.  The
#    YAML format is suitable for embedding in Hugo front matter and is
#    compatible with the hugo-table-shortcode syntax.
#
#    Both CSV and YAML table output is written to standard output.
#
# 2. Generate a temporary CSV format in the range [1, 50] with no values
#    elided.  This temporary CSV is passed to plot.py to generate an
#    SVG.
#
#    Note: SVG mode writes to the path in the BDAY_SVG_PATH environment
#    variable if it is specified, or to ./birthday-paradox-chart.svg if
#    BDAY_SVG_PATH is not set.
#
# (Range and elided rows can be configured using the values in the
# counts and elided values in the PROFILES map below, respectively.
#

# load libraries
require 'csv'
require 'yaml'
require 'tempfile'

PROFILES = {
  # profile for HTML table and CSV
  table: {
    # occupancy counts to calculate (inclusive)
    counts: (1..25).to_a,

    # occupancy counts to elide (inclusive)
    elided: (5..21).to_a,
  },

  # profile for SVG chart
  chart: {
    # show from 1-50 (inclusive)
    counts: (1..50).to_a,

    # do not omit any values
    elided: [],
  },
}

# css for highlighted rows in YAML output
HIGHLIGHT_CSS = 'has-text-weight-bold has-background-info-light'

# column headers
# used to generate both the CSV and YAML output
COLS = [{
  'id'    => 'num_people',
  'name'  => "Number of People",
  'tip'   => "Number of people in room.",
}, {
  'id'    => 'probability',
  'name'  => "Probability",
  'tip'   => "Probability that at least two people in a room with this many people share a birthday.",
}, {
  'id'    => 'percent',
  'name'  => "Percent",
  'tip'   => "Probability represented as a percentage.",
  'align' => "right",
}]

# build path to plot.py (in current dir)
PLOT_PATH = File.join(__dir__, 'plot.py') 

class Integer
  #
  # Calculate factorial of a non-negative integer.
  #
  # Raises an exception if the value is not an integer or if the value is
  # less than zero.
  #
  def factorial
    raise "value is negative" unless self >= 0

    # calculate factorial iteratively, not recursively
    (self > 1) ? self.downto(1).reduce(1) { |r, t| r * t } : 1
  end
end

# memoize 365!
F365 = 365.factorial

#
# Return the probability that at least one pair of people in a room of N
# people share a birthday.
#
# (This is the formula that we derived in the original article).
#
def shared_birthdays(v)
  1 - F365 / (365 - v).factorial * (365 ** -v)
end

#
# Write CSV of given rows to IO with the following columns
#
# * "Number of People": Number of people in room.
# * "Probability": Probability that at least two people share the
#   same birthday (truncated to 5 decimal places).
# * Percent: Probability converted to a percentage.
#
def write_csv(io, rows)
  CSV(io) do |csv|
    # write column headers
    csv << COLS.map { |col| col['name'] }

    # write results for 1 through 25
    rows.each do |row|
      if row[:elided]
        # write elided marker
        csv << %w{...}
      else
        # write row to csv
        csv << [
          row[:num_people],
          '%0.5f' % [row[:probability]],
          row[:percent],
        ]
      end
    end
  end
end

#
# Write YAML for Hugo table shortcode to standard output with the
# following columns:
#
# * num_people: number of people in room.
# * probability: probability that at least two people share the
#   same birthday (truncated to 5 decimal places).
# * percent: probability converted to a percentage.
#
def write_yaml(io, rows)
  io.puts YAML.dump({
    'tables' => {
      'probs' => {
        'cols' => COLS,
        'rows' => rows.map { |row|
          if row[:elided]
            # elided rows
            { 'num_people' => '...' }
          else
            # map row to YAML hash
            {
              'num_people'  => row[:num_people],
              'probability' => row[:probability],
              'percent'     => row[:percent]
            }.merge(row[:probability] > 0.5 ? {
              # highlight matching rows
              '_css' => HIGHLIGHT_CSS,
            } : {})
          end
        },
      },
    },
  })
end

#
# Write CSV to temporary file, then invoke plot.py to generate an SVG
# and write it to the given path.
#
def write_svg(svg_path, rows)
  # create temp file
  Tempfile.open('birthday-paradox-') do |io|
    # write csv, close temp file (but keep it around)
    write_csv(io, ROWS)
    io.flush
    io.close(false)

    # exec plot
    system('/usr/bin/python3', PLOT_PATH, io.path, svg_path)
  end
end

# check command-line argument
raise "Usage: #$0 <csv|yaml|svg>" unless ARGV.size == 1

# determine profile from output format
PROFILE = PROFILES[(ARGV.first == 'svg') ? :chart : :table]

# build rows
ROWS = (PROFILE[:counts] - PROFILE[:elided]).each.with_object([]) do |v, r|
  # calculate the shared birthdays probability
  # (convert to float to get decimal representation)
  b = shared_birthdays(v).to_f

  # emit row
  r << {
    # number of people
    num_people: v,

    # probability, truncated to 5 decimal
    probability: b.truncate(5),

    # probability converted to a percentage
    percent: '%2.2f%%' % [100 * b],
  }

  # emit elided marker for table profile
  if PROFILE[:elided].size > 0 && v == PROFILE[:elided].first - 1
    # emit elided marker
    r << { elided: true }
  end
end

# check format argument
case ARGV.first
when 'yaml'
  # write yaml to stdout
  write_yaml(STDOUT, ROWS)
when 'csv'
  # write csv to standard output
  write_csv(STDOUT, ROWS)
when 'svg'
  # get svg path, default to birthday-paradox-chart.svg
  svg_path = ENV.fetch('BDAY_SVG_PATH', 'birthday-paradox-chart.svg')

  # write svg to given path
  write_svg(svg_path, ROWS)
else
  # unknown format
  raise "unknown format: #{ARGV.first}"
end
