module UI
  # ── ANSI escape helpers ────────────────────────────────────────────────────
  RESET   = "\e[0m"
  BOLD    = "\e[1m"
  DIM     = "\e[2m"
  ITALIC  = "\e[3m"
  UNDER   = "\e[4m"

  # 256-color foreground
  def self.fg(n) = "\e[38;5;#{n}m"
  def self.bg(n) = "\e[48;5;#{n}m"

  # Palette — LegendaryOS brand colours
  C_GOLD    = fg(220)   # #ffd700 — primary accent
  C_AMBER   = fg(214)   # #ffaf00 — secondary
  C_RED     = fg(196)   # bright red — errors
  C_GREEN   = fg(82)    # bright green — success
  C_CYAN    = fg(87)    # bright cyan — info
  C_PURPLE  = fg(135)   # purple — highlight
  C_GREY    = fg(244)   # medium grey
  C_LGREY   = fg(250)   # light grey
  C_WHITE   = fg(255)   # near-white
  C_DARK    = fg(234)   # near-black (for bg blocks)

  BG_DARK   = bg(232)
  BG_PANEL  = bg(235)

  # Terminal width
  def self.cols = [(`tput cols 2>/dev/null`.to_i), 80].max

  # ── Init ──────────────────────────────────────────────────────────────────
  def self.init
    # Enable UTF-8 box-drawing if terminal supports it
    @unicode = ENV['TERM'] != 'dumb' && !ENV['NO_UNICODE']
  end

  # ── Primitives ────────────────────────────────────────────────────────────
  def self.paint(*parts)
    parts.join + RESET
  end

  def self.puts_colored(text, color = C_WHITE)
    $stdout.puts paint(color, text)
  end

  def self.hr(char: '─', color: C_GREY)
    puts paint(color, char * cols)
  end

  def self.blank = $stdout.puts

  # ── BANNER ────────────────────────────────────────────────────────────────
  LOGO = <<~'ASCII'
     ██╗     ██████╗ ███╗   ███╗
     ██║     ██╔══██╗████╗ ████║
     ██║     ██████╔╝██╔████╔██║
     ██║     ██╔═══╝ ██║╚██╔╝██║
     ███████╗██║     ██║ ╚═╝ ██║
     ╚══════╝╚═╝     ╚═╝     ╚═╝
  ASCII

  def self.banner
    blank
    LOGO.each_line do |line|
      # Gradient: gold → amber per char group
      styled = line.chars.each_with_index.map do |ch, i|
        color = i % 6 < 3 ? C_GOLD : C_AMBER
        paint(BOLD, color, ch)
      end.join
      $stdout.print '  ' + styled
    end

    w = cols
    tagline = "#{BOLD}#{C_GOLD}LegendaryOS Package Manager#{RESET}  " \
              "#{DIM}#{C_GREY}v#{LPM::VERSION}#{RESET}"
    sub     = "#{DIM}#{C_GREY}Powered by bootc · Fedora Immutable#{RESET}"

    $stdout.puts center_ansi(tagline, w)
    $stdout.puts center_ansi(sub, w)
    blank
    hr(char: '═', color: C_GOLD)
    blank
  end

  # Centers a string that contains ANSI codes (strip for length calc)
  def self.center_ansi(str, width)
    visible_len = str.gsub(/\e\[[0-9;]*m/, '').length
    padding = [(width - visible_len) / 2, 0].max
    ' ' * padding + str
  end

  # ── SECTION HEADER ────────────────────────────────────────────────────────
  def self.section(title, icon: '◆')
    blank
    $stdout.puts paint(BOLD, C_GOLD, " #{icon} #{title.upcase}")
    hr(char: '─', color: C_AMBER)
  end

  # ── STATUS MESSAGES ───────────────────────────────────────────────────────
  def self.success(msg)
    $stdout.puts paint(C_GREEN,  BOLD, ' ✔ ') + paint(C_WHITE, msg)
  end

  def self.error(msg)
    $stdout.puts paint(C_RED,    BOLD, ' ✖ ') + paint(C_WHITE, msg)
  end

  def self.warn(msg)
    $stdout.puts paint(C_AMBER,  BOLD, ' ⚠ ') + paint(C_WHITE, msg)
  end

  def self.info(msg)
    $stdout.puts paint(C_CYAN,   BOLD, ' ℹ ') + paint(C_WHITE, msg)
  end

  def self.step(msg)
    $stdout.puts paint(C_PURPLE, BOLD, ' → ') + paint(C_LGREY, msg)
  end

  # ── BOX ───────────────────────────────────────────────────────────────────
  def self.box(lines, title: nil, color: C_GOLD, width: nil)
    w = width || [cols - 4, 60].min
    tl, tr, bl, br = '╔', '╗', '╚', '╝'
    h,  v           = '═', '║'

    top_border =
      if title
        pad = w - title.length - 2
        "#{tl}#{h} #{title} #{h * [pad, 0].max}#{tr}"
      else
        "#{tl}#{h * w}#{tr}"
      end

    blank
    $stdout.puts paint(color, top_border)
    lines.each do |line|
      visible = line.gsub(/\e\[[0-9;]*m/, '')
      inner   = w - 2
      padding = [inner - visible.length, 0].max
      $stdout.puts paint(color, "#{v} ") + line + ' ' * padding + paint(color, " #{v}")
    end
    $stdout.puts paint(color, "#{bl}#{h * w}#{br}")
    blank
  end

  # ── KEY/VALUE TABLE ───────────────────────────────────────────────────────
  def self.kv_table(pairs, key_color: C_GOLD, val_color: C_WHITE, indent: 4)
    key_w = pairs.map { |k, _| k.to_s.length }.max.to_i
    pairs.each do |key, val|
      k = paint(key_color, BOLD, key.to_s.ljust(key_w))
      v = paint(val_color, val.to_s)
      $stdout.puts ' ' * indent + "#{k}  #{paint(C_GREY, '│')}  #{v}"
    end
  end

  # ── PROGRESS BAR ─────────────────────────────────────────────────────────
  def self.progress(label, pct, width: 40)
    filled = (pct * width / 100.0).round
    empty  = width - filled
    bar    = paint(BG_PANEL, C_GOLD,  '█' * filled) +
             paint(BG_PANEL, C_GREY,  '░' * empty)  +
             RESET
    pct_str = paint(BOLD, C_WHITE, "#{pct.to_i}%".rjust(4))
    $stdout.print "\r  #{paint(C_LGREY, label.ljust(20))} #{bar} #{pct_str}"
    $stdout.flush
    $stdout.puts if pct >= 100
  end

  # ── CONFIRM PROMPT ────────────────────────────────────────────────────────
  def self.confirm(question, default: false)
    hint = default ? '[Y/n]' : '[y/N]'
    $stdout.print "\n  #{paint(BOLD, C_GOLD, '?')} #{paint(C_WHITE, question)} " \
                  "#{paint(DIM, C_GREY, hint)} "
    $stdout.flush
    input = $stdin.gets&.strip&.downcase
    input.nil? || input.empty? ? default : input.start_with?('y')
  end

  # ── REBOOT NOTICE ─────────────────────────────────────────────────────────
  def self.reboot_notice
    box(
      [
        paint(C_AMBER, BOLD, '  A system reboot is required to apply changes.'),
        '',
        paint(C_LGREY, '  Run: ') + paint(C_CYAN, BOLD, 'systemctl reboot'),
        paint(C_LGREY, '  Or:  ') + paint(C_CYAN, BOLD, 'lpm reboot'),
      ],
      title: ' REBOOT REQUIRED ',
      color: C_AMBER,
      width: 56
    )
  end
end
