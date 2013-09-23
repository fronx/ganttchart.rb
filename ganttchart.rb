# encoding: utf-8
require 'csv'
require 'time'

class GanttChart
  FILLER_CHAR      = '.'
  BAR_CHAR         = '▓'
  DIVIDER_CHAR     = '|'
  DAY_DIVIDER_CHAR = '║'

  def initialize(rows, screen_width, divide_every_h)
    @start_time   = rows.map { |(_, x, _)| x }.min
    @end_time     = rows.map { |(_, _, x)| x }.max
    @label_length = rows.map { |(x, _, _)| x.length }.max
    @time_frame   = @end_time - @start_time
    @screen_width = screen_width
    @rows = rows
    @divide_every_h = divide_every_h
  end

  def to_s
    [
      output_rows.map { |label, bars| "#{label} #{bars}" },
      summary_row,
      "START TIME: #{@start_time}",
      "END TIME:   #{@end_time}",
    ].join("\n")
  end

  def divisions
    return @divisions if @divisions
    @divisions = []
    last_hour = nil
    times.each_with_index do |time, i|
      if (time.hour != last_hour) &&
         (time.hour % @divide_every_h == 0)
        last_hour = time.hour
        @divisions << [ i, time.hour ]
      end
    end
    @divisions
  end

  def divide(line)
    overhead = 0
    divisions.each do |(i, hour)|
      line.insert(i + overhead, hour == 0 ? DAY_DIVIDER_CHAR : DIVIDER_CHAR)
      overhead += 1
    end
    line
  end

  def times
    @times ||=
      (0..@screen_width).map do |n|
        @start_time + n.to_f * @time_frame / @screen_width
      end
  end

  def output_rows
    @output_rows ||=
      @rows.group_by(&:first).map do |label, rows|
        [
          "%#{@label_length}s" % label,
          divide(
            string_or(
              filler_row,
              inject_string_or(rows.map { |(_, a, b)| time_range_to_string(a, b) })
            )
          ),
        ]
      end
  end

  def summary_row
    empty_label + inject_string_or(output_rows.map(&:last))
  end

  def empty_label
    (' ' * (@label_length + 1))
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

filename       = ARGV[0]
screen_width   = (ARGV[1] || 200).to_i
divide_every_h = (ARGV[2] || 6).to_i

rows = CSV.read(filename)[1..-1].map do |(label, start_time, end_time)|
  [ label, Time.parse(start_time), Time.parse(end_time) ]
end

puts GanttChart.new(rows, screen_width, divide_every_h).to_s
