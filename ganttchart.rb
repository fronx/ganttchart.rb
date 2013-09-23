# encoding: utf-8
require 'csv'
require 'time'

class GanttChart
  FILLER_CHAR = '.'
  BAR_CHAR    = '▓'

  def initialize(rows, screen_width)
    @start_time   = rows.map { |(_, x, _)| x }.min
    @end_time     = rows.map { |(_, _, x)| x }.max
    @label_length = rows.map { |(x, _, _)| x.length }.max
    @time_frame   = @end_time - @start_time
    @screen_width = screen_width
    @rows = rows
  end

  def to_s
    [
      output_rows.map { |label, bars| "#{label} #{bars}" },
      (' ' * (@label_length + 1)) + inject_string_or(output_rows.map(&:last)),
      "START TIME: #{@start_time}",
      "END TIME:   #{@end_time}",
    ].join("\n")
  end

  def output_rows
    @output_rows ||=
      @rows.group_by(&:first).map do |label, rows|
        [
          "%#{@label_length}s" % label,
          string_or(
            filler_row,
            inject_string_or(rows.
              map { |(_, a, b)| time_range_to_string(a, b) }
            )
          ),
        ]
      end
  end

  def inject_string_or(strings)
    strings.inject { |acc, s| string_or(acc, s) }
  end

  def filler_row
    FILLER_CHAR * @screen_width
  end

  def duration_to_chars(duration)
    (@screen_width * duration / @time_frame).to_i
  end

  def bar(length)
    BAR_CHAR * length
  end

  def time_range_to_string(a, b)
    FILLER_CHAR * duration_to_chars(a - @start_time) + bar(duration_to_chars(b - a))
  end

  def string_or(a, b, whitespace=['.', ' '], filler=FILLER_CHAR)
    bs, as = [ a, b ].sort_by(&:length)
    as.chars.zip(bs.chars).
      map do |a, b|
        whitespace.include?(a) ? b || filler : a
      end.join('')
  end
end

filename = ARGV[0]
screen_width = (ARGV[1] || 200).to_i

rows = CSV.read(filename)[1..-1].map do |(label, start_time, end_time)|
  [ label, Time.parse(start_time), Time.parse(end_time) ]
end

puts GanttChart.new(rows, screen_width).to_s
