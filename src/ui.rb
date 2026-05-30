module UI
  # ── ANSI escape helpers ────────────────────────────────────────────────────
  RESET   = "\e[0m"
  BOLD    = "\e[1m"
  DIM     = "\e[2m"
  ITALIC  = "\e[3m"
  UNDER   = "\e[4m"
  BLINK   = "\e[5m"

  def self.fg(n) = "\e[38;5;#{n}m"
  def self.bg(n) = "\e[48;5;#{n}m"

  # ── LegendaryOS Palette (from logo: black bg, purple/magenta/cyan neon) ───
  C_MAGENTA  = fg(201)  # #ff00ff — hot magenta (primary neon)
  C_PINK     = fg(198)  # #ff0087 — deep pink
  C_PURPLE   = fg(135)  # #af5fff — mid purple
  C_VIOLET   = fg(99)   # #875fff — dark violet
  C_CYAN     = fg(51)   # #00ffff — electric cyan (accent)
  C_BLUE     = fg(63)   # #5f5fff — deep blue
  C_WHITE    = fg(255)  # near-white
  C_LGREY    = fg(250)  # light grey
  C_GREY     = fg(244)  # medium grey
  C_DGREY    = fg(238)  # dark grey
  C_RED      = fg(196)  # bright red — errors
  C_GREEN    = fg(46)   # bright green — success
  C_AMBER    = fg(214)  # amber — warnings
  C_GOLD     = fg(220)  # gold (kept for compat)

  # Background blocks
  BG_DARK    = bg(16)   # pure black
  BG_PANEL   = bg(232)  # near-black panel
  BG_DEEP    = bg(17)   # very dark blue-black

  # Primary accent for this skin
  C_ACCENT   = C_MAGENTA
  C_ACCENT2  = C_CYAN

  def self.cols
    w = `tput cols 2>/dev/null`.to_i rescue 0
    [w, 80].max
  end

  def self.init
    @unicode = ENV['TERM'] != 'dumb' && !ENV['NO_UNICODE']
  end

  def self.paint(*parts)
    parts.join + RESET
  end

  def self.hr(char: '─', color: C_VIOLET)
    $stdout.puts paint(color, char * cols)
  end

  def self.blank
    $stdout.puts
  end

  # ── BANNER ────────────────────────────────────────────────────────────────
  # Pixel-style phoenix logo in ASCII, matching the LegendaryOS brand
  LOGO_LINES = [
    '    ██╗     ███████╗ ██████╗ ███████╗███╗   ██╗██████╗  █████╗ ██████╗ ██╗   ██╗',
    '    ██║     ██╔════╝██╔════╝ ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝',
    '    ██║     █████╗  ██║  ███╗█████╗  ██╔██╗ ██║██║  ██║███████║██████╔╝ ╚████╔╝ ',
    '    ██║     ██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║██║  ██║██╔══██║██╔══██╗  ╚██╔╝  ',
    '    ███████╗███████╗╚██████╔╝███████╗██║ ╚████║██████╔╝██║  ██║██║  ██║   ██║   ',
    '    ╚══════╝╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ',
    '',
    '           ░▒▓█  ██████╗ ███████╗  █████████████╗   ███╗█████╗████████╗  █▓▒░    ',
    ].freeze

  PHOENIX = [
    '          ░  ▓██▓░   ╔╦╦╦╗    ╔╦╦╦╗   ░▓██▓░  ░',
    '        ░ ▒████▒  ╔══╬╬╬╬╬╗  ╔╬╬╬╬╬══╗  ▒████▒ ░',
    '       ░▒██████▓╗╔╬╬╬╬╬╬╬╬╬╗╔╬╬╬╬╬╬╬╬╬╗╔▓██████▒░',
    '      ░▒▓███████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬███████▓▒░',
    '       ░▒▓██████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██████▓▒░',
    '          ░▒▓███╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬███▓▒░',
    '             ░▒▓█╬╬╬╬╬╬╬▓▒░░░▒▓╬╬╬╬╬╬╬█▓▒░',
    '                ░▒▓╬╬╬╬╬▒░   ░▒╬╬╬╬╬▓▒░',
    '                  ░▒▓╬╬╬╬╬╬╬╬╬╬╬╬╬▓▒░',
    '                    ░░▒▒▓▓███▓▓▒▒░░',
    ].freeze

  def self.banner
    blank
    # Gradient phoenix: magenta left → purple center → cyan right
    PHOENIX.each_with_index do |line, i|
      ratio = i.to_f / PHOENIX.size
      color = ratio < 0.4 ? C_MAGENTA : (ratio < 0.7 ? C_PURPLE : C_VIOLET)
      $stdout.puts paint(BOLD, color, line)
    end
    blank

    w = cols
    # "LEGENDARY OS" in neon gradient
    title_parts = []
    'LEGENDARY OS'.chars.each_with_index do |ch, i|
      pct = i.to_f / 12
      color = pct < 0.4 ? C_MAGENTA : (pct < 0.7 ? C_PURPLE : C_CYAN)
      title_parts << paint(BOLD, color, ch)
    end
    title = title_parts.join
    title_vis = 'LEGENDARY OS'

    pad = [(w - title_vis.length) / 2, 0].max
    $stdout.puts ' ' * pad + title

    sub = paint(DIM, C_VIOLET, 'Package Manager  ') + paint(DIM, C_GREY, "v#{LPM::VERSION rescue '?'}") + \
          paint(DIM, C_VIOLET, '  ·  Powered by bootc / rpm-ostree / flatpak / distrobox')
    sub_vis = sub.gsub(/\e\[[0-9;]*m/, '')
                            pad2 = [(w - sub_vis.length) / 2, 0].max
                           $stdout.puts ' ' * pad2 + sub

                           blank
                           # Neon divider: magenta ═ with purple ╬ accents
                           div_width = [cols, 90].min
                           divider = '╬' + '═' * ((div_width - 2) / 2) + '╬' + '═' * ((div_width - 2) / 2) + '╬'
                           $stdout.puts center_ansi(paint(BOLD, C_MAGENTA, divider), cols)
                           blank
                           end

                           def self.center_ansi(str, width)
                           visible_len = str.gsub(/\e\[[0-9;]*m/, '').length
                                                       padding = [(width - visible_len) / 2, 0].max
                                                      ' ' * padding + str
                                                      end

                                                      # ── SECTION HEADER ────────────────────────────────────────────────────────
                                                      def self.section(title, icon: '◈', color: C_MAGENTA)
                                                      blank
                                                      top = paint(BOLD, color, " #{icon} ") + paint(BOLD, C_WHITE, title.upcase)
                                                      $stdout.puts top
                                                      hr(char: '╌', color: C_VIOLET)
                                                      end

                                                      # ── STATUS MESSAGES ───────────────────────────────────────────────────────
                                                      def self.success(msg)
                                                      $stdout.puts paint(C_GREEN,   BOLD, ' ✔ ') + paint(C_WHITE, msg)
                                                      end

                                                      def self.error(msg)
                                                      $stdout.puts paint(C_RED,     BOLD, ' ✖ ') + paint(C_WHITE, msg)
                                                      end

                                                      def self.warn(msg)
                                                      $stdout.puts paint(C_AMBER,   BOLD, ' ⚠ ') + paint(C_WHITE, msg)
                                                      end

                                                      def self.info(msg)
                                                      $stdout.puts paint(C_CYAN,    BOLD, ' ℹ ') + paint(C_WHITE, msg)
                                                      end

                                                      def self.step(msg)
                                                      $stdout.puts paint(C_PURPLE,  BOLD, ' → ') + paint(C_LGREY, msg)
                                                      end

                                                      def self.note(msg)
                                                      $stdout.puts paint(C_VIOLET,  BOLD, ' ◆ ') + paint(C_GREY, msg)
                                                      end

                                                      # ── BOX with neon border ───────────────────────────────────────────────────
                                                      def self.box(lines, title: nil, color: C_MAGENTA, width: nil)
                                                      w = width || [cols - 4, 70].min
                                                      tl, tr, bl, br = '╔', '╗', '╚', '╝'
                                                      h,  v           = '═', '║'

                                                      top_border =
                                                      if title
                                                      tpad = w - title.length - 2
                                                      "#{tl}#{h} #{title} #{h * [tpad, 0].max}#{tr}"
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
                                                                              def self.kv_table(pairs, key_color: C_MAGENTA, val_color: C_WHITE, indent: 4)
                                                                              return if pairs.empty?
                                                                              key_w = pairs.map { |k, _| k.to_s.length }.max.to_i
                                                                              pairs.each do |key, val|
                                                                              k = paint(key_color, BOLD, key.to_s.ljust(key_w))
                                                                              v = paint(val_color, val.to_s)
                                                                              $stdout.puts ' ' * indent + "#{k}  #{paint(C_VIOLET, '│')}  #{v}"
                                                                              end
                                                                              end

                                                                              # ── NEON TABLE ────────────────────────────────────────────────────────────
                                                                              def self.table(headers, rows, colors: nil)
                                                                              cols_w = headers.each_with_index.map do |h, i|
                                                                              [h.length, *rows.map { |r| r[i].to_s.length }].max
                                                                              end

                                                                              sep   = paint(C_VIOLET, ' │ ')
                                                                              hline = paint(C_VIOLET, '─' * (cols_w.sum + cols_w.size * 3 - 1))

                                                                              header_cells = headers.each_with_index.map do |h, i|
                                                                              paint(BOLD, C_MAGENTA, h.ljust(cols_w[i]))
                                                                              end
                                                                              $stdout.puts '  ' + header_cells.join(sep)
                                                                              $stdout.puts '  ' + hline

                                                                              rows.each_with_index do |row, ri|
                                                                              cells = row.each_with_index.map do |cell, i|
                                                                              color = colors&.dig(ri, i) || C_LGREY
                                                                              paint(color, cell.to_s.ljust(cols_w[i]))
                                                                              end
                                                                              $stdout.puts '  ' + cells.join(sep)
                                                                              end
                                                                              end

                                                                              # ── CONFIRM PROMPT ────────────────────────────────────────────────────────
                                                                              def self.confirm(question, default: false)
                                                                              hint = default ? '[Y/n]' : '[y/N]'
                                                                              $stdout.print "\n  #{paint(BOLD, C_MAGENTA, '?')} #{paint(C_WHITE, question)} " \
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
                                                                                  title: ' ⏻  REBOOT REQUIRED ',
                                                                                  color: C_AMBER,
                                                                                  width: 58
                                                                                 )
                                                                              end

                                                                              # ── BACKEND BADGE ─────────────────────────────────────────────────────────
                                                                              def self.backend_badge(name)
                                                                              colors = {
                                                                                        'bootc'       => C_CYAN,
                                                                                        'rpm-ostree'  => C_MAGENTA,
                                                                                        'flatpak'     => C_PURPLE,
                                                                                        'distrobox'   => C_VIOLET,
                                                                                        'toolbox'     => C_BLUE,
                                                                                        }
                                                                              c = colors[name] || C_GREY
                                                                              paint(c, BOLD, "[#{name}]")
                                                                              end

                                                                              # ── PROGRESS BAR ─────────────────────────────────────────────────────────
                                                                              def self.progress(label, pct, width: 36)
                                                                              filled = (pct * width / 100.0).round
                                                                              empty  = width - filled
                                                                              bar    = paint(C_MAGENTA, '█' * filled) +
                                                                              paint(C_DGREY,   '░' * empty)
                                                                              pct_str = paint(BOLD, C_WHITE, "#{pct.to_i}%".rjust(4))
                                                                              $stdout.print "\r  #{paint(C_LGREY, label.to_s.ljust(22))} #{bar} #{pct_str}"
                                                                              $stdout.flush
                                                                              $stdout.puts if pct >= 100
                                                                              end
                                                                              end
