require 'io/console'

module Spinner
  FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
  DONE   = '✔'
  FAIL   = '✖'

  # Runs a block while showing a spinner.
  # Returns [exit_status, stdout_lines]
  #
  # Spinner.run("Fetching image…") { system("bootc upgrade") }
  def self.run(label, color: UI::C_GOLD, &block)
    done    = false
    success = true
    result  = nil
    frame_i = 0

    # Hide cursor
    $stdout.print "\e[?25l"

    spinner_thread = Thread.new do
      until done
        frame = UI.paint(UI::BOLD, color, FRAMES[frame_i % FRAMES.size])
        lbl   = UI.paint(UI::C_LGREY, label)
        $stdout.print "\r  #{frame}  #{lbl}   "
        $stdout.flush
        sleep 0.08
        frame_i += 1
      end
    end

    begin
      result  = block.call
      success = result != false
    rescue => e
      success = false
      @last_error = e.message
    ensure
      done = true
      spinner_thread.join
    end

    # Final status line
    if success
      tick = UI.paint(UI::BOLD, UI::C_GREEN, DONE)
      msg  = UI.paint(UI::C_WHITE, label)
      $stdout.puts "\r  #{tick}  #{msg}   "
    else
      cross = UI.paint(UI::BOLD, UI::C_RED, FAIL)
      msg   = UI.paint(UI::C_WHITE, label)
      $stdout.puts "\r  #{cross}  #{msg}   "
    end

    # Restore cursor
    $stdout.print "\e[?25h"
    $stdout.flush

    [success, result]
  end

  # Stream command output with a live prefix indicator
  def self.stream(label, cmd)
    UI.step label
    UI.blank

    IO.popen("#{cmd} 2>&1", 'r') do |io|
      io.each_line do |line|
        $stdout.print "    #{UI.paint(UI::DIM, UI::C_GREY, '│')}  #{UI.paint(UI::C_LGREY, line.chomp)}\n"
        $stdout.flush
      end
    end
    $?.success?
  end
end
