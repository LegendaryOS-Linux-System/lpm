require 'io/console'

module Spinner
  # Neon pixel-style spinner frames
  FRAMES = %w[◈ ◇ ◆ ◉ ○ ● ◉ ◆ ◇].freeze
  DONE   = '✔'
  FAIL   = '✖'

  def self.run(label, color: UI::C_MAGENTA, &block)
    done    = false
    success = true
    frame_i = 0

    $stdout.print "\e[?25l" # hide cursor

    spinner_thread = Thread.new do
      until done
        frame = UI.paint(UI::BOLD, color, FRAMES[frame_i % FRAMES.size])
        lbl   = UI.paint(UI::C_LGREY, label)
        $stdout.print "\r  #{frame}  #{lbl}   "
        $stdout.flush
        sleep 0.1
        frame_i += 1
      end
    end

    begin
      result  = block.call
      success = result != false
    rescue => e
      success = false
    ensure
      done = true
      spinner_thread.join
    end

    if success
      tick = UI.paint(UI::BOLD, UI::C_GREEN, DONE)
      $stdout.puts "\r  #{tick}  #{UI.paint(UI::C_WHITE, label)}   "
    else
      cross = UI.paint(UI::BOLD, UI::C_RED, FAIL)
      $stdout.puts "\r  #{cross}  #{UI.paint(UI::C_WHITE, label)}   "
    end

    $stdout.print "\e[?25h" # restore cursor
    $stdout.flush
    [success, nil]
  end

  def self.stream(label, cmd)
    UI.step label
    UI.blank
    IO.popen("#{cmd} 2>&1", 'r') do |io|
      io.each_line do |line|
        $stdout.print "    #{UI.paint(UI::DIM, UI::C_VIOLET, '│')}  " \
                      "#{UI.paint(UI::C_LGREY, line.chomp)}\n"
        $stdout.flush
      end
    end
    $?.success?
  end

  # Stream a block that yields lines
  def self.stream_block(label)
    UI.step label
    UI.blank
    yield ->(line) {
      $stdout.print "    #{UI.paint(UI::DIM, UI::C_VIOLET, '│')}  " \
    "#{UI.paint(UI::C_LGREY, line.chomp)}\n"
    $stdout.flush
    }
  end
end
