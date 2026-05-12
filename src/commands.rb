module Commands
  HELP_TEXT = <<~HELP
    #{UI.paint(UI::BOLD, UI::C_GOLD, 'USAGE')}
      lpm <command> [options]

    #{UI.paint(UI::BOLD, UI::C_GOLD, 'COMMANDS')}
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'status')}        Show current system image status
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'upgrade')}       Pull and stage the latest image
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'check')}         Check if an update is available (no download)
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'switch')}        Switch to a different image
                  lpm switch <image-reference>
                  lpm switch <image> --transport <oci|registry|containers-storage>
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'rollback')}      Activate the previous (rollback) image
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'reboot')}        Reboot system to apply staged image
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'version')}       Show lpm version
      #{UI.paint(UI::BOLD, UI::C_WHITE, 'help')}          Show this help message

    #{UI.paint(UI::BOLD, UI::C_GOLD, 'EXAMPLES')}
      lpm upgrade
      lpm switch ghcr.io/legendaryos/base:latest
      lpm switch oci-archive:/path/to/image.tar --transport oci
      lpm rollback && lpm reboot
  HELP

  def self.run(argv)
    UI.banner

    cmd  = argv.shift&.downcase
    args = argv

    case cmd
    when 'status',   's'     then cmd_status
    when 'upgrade',  'up'    then cmd_upgrade
    when 'check',    'c'     then cmd_check
    when 'switch',   'sw'    then cmd_switch(args)
    when 'rollback', 'rb'    then cmd_rollback
    when 'reboot'            then cmd_reboot
    when 'version',  '-v',
         '--version'         then cmd_version
    when 'help', '-h',
         '--help', nil       then cmd_help
    else
      UI.error "Unknown command: '#{cmd}'"
      UI.blank
      $stdout.puts HELP_TEXT
      exit 1
    end
  end

  # ── status ────────────────────────────────────────────────────────────────
  def self.cmd_status
    UI.section '系统状态  System Status', icon: '◉'

    st = nil
    Spinner.run('Reading system state…') { st = Bootc.status; true }

    if st[:error]
      UI.error st[:error]
      exit 1
    end

    # ── Booted image ──────────────────────────────────────────────────────
    UI.blank
    $stdout.puts UI.paint(UI::BOLD, UI::C_GOLD, '  ▸ BOOTED IMAGE')
    UI.kv_table([
      ['Image',   st[:booted_image]],
      ['Version', st[:booted_ver]],
      ['Digest',  st[:booted_digest]],
      ['Date',    st[:booted_ts]],
    ])

    # ── Staged image ──────────────────────────────────────────────────────
    if st[:staged?]
      UI.blank
      $stdout.puts UI.paint(UI::BOLD, UI::C_CYAN, '  ▸ STAGED  (pending reboot)')
      UI.kv_table([
        ['Image',   st[:staged_image]],
        ['Version', st[:staged_ver]],
        ['Digest',  st[:staged_digest]],
      ], key_color: UI::C_CYAN)
      UI.reboot_notice
    else
      UI.blank
      UI.info 'No staged image — system is up-to-date or no upgrade fetched yet.'
    end

    # ── Rollback ──────────────────────────────────────────────────────────
    if st[:rollback?]
      UI.blank
      $stdout.puts UI.paint(UI::BOLD, UI::C_PURPLE, '  ▸ ROLLBACK AVAILABLE')
      UI.kv_table([
        ['Image',   st[:rollback_image]],
        ['Version', st[:rollback_ver]],
      ], key_color: UI::C_PURPLE)
    end

    UI.blank
  end

  # ── upgrade ───────────────────────────────────────────────────────────────
  def self.cmd_upgrade
    UI.section 'Upgrade System', icon: '↑'
    UI.info 'Pulling latest image and staging for next boot…'
    UI.blank

    ok = Spinner.stream('bootc upgrade', 'bootc upgrade')

    UI.blank
    if ok
      UI.success 'Image staged successfully!'
      UI.reboot_notice
    else
      UI.error 'Upgrade failed. Check output above for details.'
      exit 1
    end
  end

  # ── check ─────────────────────────────────────────────────────────────────
  def self.cmd_check
    UI.section 'Check for Updates', icon: '⟳'

    ok = avail = out = nil
    Spinner.run('Querying registry…') do
      ok, avail, out, = Bootc.check
      true
    end

    UI.blank
    if avail
      UI.success 'Update available! Run lpm upgrade to fetch it.'
    else
      UI.info 'System is up-to-date.'
    end

    unless out.empty?
      UI.blank
      $stdout.puts UI.paint(UI::DIM, UI::C_GREY, out.gsub(/^/, '    '))
    end
    UI.blank
  end

  # ── switch ────────────────────────────────────────────────────────────────
  def self.cmd_switch(args)
    UI.section 'Switch Image', icon: '⇄'

    image = args.shift
    unless image
      UI.error 'No image specified.'
      UI.step  'Usage: lpm switch <image-reference>'
      exit 1
    end

    transport = nil
    if (idx = args.index('--transport') || args.index('-t'))
      transport = args[idx + 1]
    end

    UI.blank
    UI.kv_table([
      ['Target image', image],
      ['Transport',   transport || 'registry (default)'],
    ])
    UI.blank

    unless UI.confirm('Switch to this image?', default: false)
      UI.warn 'Aborted.'
      UI.blank
      return
    end

    UI.blank
    UI.info 'Switching image and staging for next boot…'
    UI.blank

    ok = Spinner.stream('bootc switch', "bootc switch #{image}" \
                        "#{transport ? " --transport #{transport}" : ''}")

    UI.blank
    if ok
      UI.success "Switched to #{image}"
      UI.reboot_notice
    else
      UI.error 'Switch failed. Check output above for details.'
      exit 1
    end
  end

  # ── rollback ──────────────────────────────────────────────────────────────
  def self.cmd_rollback
    UI.section 'Rollback', icon: '↩'

    UI.warn 'This will activate the previous (rollback) image on next boot.'
    unless UI.confirm('Continue with rollback?', default: false)
      UI.warn 'Aborted.'
      UI.blank
      return
    end

    ok = err = nil
    Spinner.run('Activating rollback image…') do
      ok, _, err = Bootc.rollback
      ok
    end

    UI.blank
    if ok
      UI.success 'Rollback image activated.'
      UI.reboot_notice
    else
      UI.error "Rollback failed: #{err}"
      exit 1
    end
  end

  # ── reboot ────────────────────────────────────────────────────────────────
  def self.cmd_reboot
    UI.section 'Reboot', icon: '⏻'

    unless UI.confirm('Reboot system now?', default: false)
      UI.warn 'Reboot cancelled.'
      UI.blank
      return
    end

    UI.blank
    UI.info 'Rebooting LegendaryOS…'
    sleep 1
    system('systemctl reboot')
  end

  # ── version ───────────────────────────────────────────────────────────────
  def self.cmd_version
    UI.box(
      [
        UI.paint(UI::BOLD, UI::C_WHITE, "  #{LPM::NAME}  #{UI.paint(UI::C_GOLD, "v#{LPM::VERSION}")}"),
        UI.paint(UI::C_GREY,  "  #{LPM::DISTRO} Package Manager"),
        '',
        UI.paint(UI::DIM, UI::C_GREY, '  Backed by bootc & Fedora 44 Immutable'),
        UI.paint(UI::DIM, UI::C_GREY, '  github.com/legendaryos/lpm'),
      ],
      title: ' VERSION ',
      color: UI::C_GOLD,
      width: 50
    )
  end

  # ── help ──────────────────────────────────────────────────────────────────
  def self.cmd_help
    $stdout.puts HELP_TEXT
    UI.blank
  end
end
