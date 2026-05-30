module Commands

  HELP_TEXT = <<~HELP

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, 'USAGE')}
  lpm <command> [subcommand] [options]

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, '── SYSTEM IMAGE')} #{UI.paint(UI::DIM, UI::C_GREY, '(bootc / rpm-ostree)')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'status')}              Show full system status (image + layers + containers)
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'upgrade')}             Pull and stage the latest base image
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'check')}               Check for update without downloading
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'switch')} <image>      Switch to a different base image #{UI.paint(UI::DIM, UI::C_GREY, '[bootc only]')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'rollback')}            Activate previous (rollback) image
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'reboot')}              Reboot to apply staged image

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, '── RPM LAYERS')} #{UI.paint(UI::DIM, UI::C_GREY, '(rpm-ostree only)')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'pkg install')} <pkgs>  Layer RPM packages onto the base image
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'pkg remove')}  <pkgs>  Remove layered RPM packages
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'pkg list')}            List all layered RPM packages

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, '── FLATPAK')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'flatpak list')}        List installed Flatpak apps
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'flatpak install')} <id>  Install a Flatpak app
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'flatpak remove')}  <id>  Remove a Flatpak app
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'flatpak update')}      Update all Flatpak apps
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'flatpak search')} <q>  Search Flathub
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'flatpak cleanup')}     Remove unused Flatpak runtimes

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, '── CONTAINERS')} #{UI.paint(UI::DIM, UI::C_GREY, '(distrobox / toolbox)')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box list')}            List all containers
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box create')} <name> [image]  Create a new container
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box enter')}  <name>  Enter a container shell
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box remove')} <name>  Remove a container
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box upgrade')}         Upgrade all containers #{UI.paint(UI::DIM, UI::C_GREY, '[distrobox only]')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box export')} <ctr> app <app>    Export app to host
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'box export')} <ctr> bin <path>   Export binary to ~/.local/bin

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, '── GENERAL')}
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'version')}             Show lpm version and detected backends
  #{UI.paint(UI::BOLD, UI::C_WHITE, 'help')}                Show this help message

  #{UI.paint(UI::BOLD, UI::C_MAGENTA, 'EXAMPLES')}
  lpm upgrade
  lpm switch ghcr.io/legendaryos/base:latest
  lpm pkg install neovim ripgrep
  lpm flatpak install com.valvesoftware.Steam
  lpm box create dev fedora-toolbox:41
  lpm box enter dev
  lpm rollback && lpm reboot

  HELP

  def self.run(argv)
    UI.banner

    cmd  = argv.shift&.downcase
    args = argv

    case cmd
    when 'status',        's'        then cmd_status
    when 'upgrade',       'up'       then cmd_upgrade
    when 'check',         'c'        then cmd_check
    when 'switch',        'sw'       then cmd_switch(args)
    when 'rollback',      'rb'       then cmd_rollback
    when 'reboot'                    then cmd_reboot
    when 'pkg',           'package'  then cmd_pkg(args)
    when 'flatpak',       'fp'       then cmd_flatpak(args)
    when 'box', 'distrobox', 'toolbox' then cmd_box(args)
    when 'version',       '-v', '--version' then cmd_version
    when 'help',          '-h', '--help', nil then cmd_help
    else
      UI.error "Unknown command: '#{cmd}'"
      UI.blank
      $stdout.puts HELP_TEXT
      exit 1
    end
  end

  # ══════════════════════════════════════════════════════════════════════════
  # STATUS
  # ══════════════════════════════════════════════════════════════════════════
  def self.cmd_status
    UI.section '系统状态  System Status', icon: '◈'

    backend = Backend.detect
    st      = nil
    Spinner.run("Reading system state via #{Backend.name}…") do
      st = backend == :bootc ? Bootc.status : RpmOstree.status
      true
    end

    if st[:error]
      UI.error st[:error]
      exit 1
    end

    UI.blank
    badge = UI.backend_badge(st[:backend])
    $stdout.puts UI.paint(UI::BOLD, UI::C_MAGENTA, "  ▸ BOOTED IMAGE  ") + badge
    rows = [
      ['Image',   st[:booted_image]],
      ['Version', st[:booted_ver]],
      ['Digest',  st[:booted_digest]],
      ['Date',    st[:booted_ts]],
      ]
    rows << ['Layered pkgs', st[:booted_pkgs]] if st[:booted_pkgs] && st[:booted_pkgs] != '—'
    UI.kv_table(rows)

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
      UI.info 'No staged image — system is up-to-date.'
    end

    if st[:rollback?]
      UI.blank
      $stdout.puts UI.paint(UI::BOLD, UI::C_VIOLET, '  ▸ ROLLBACK AVAILABLE')
      UI.kv_table([
                   ['Image',   st[:rollback_image]],
                   ['Version', st[:rollback_ver]],
                   ], key_color: UI::C_VIOLET)
    end

    # ── RPM layered packages ─────────────────────────────────────────────
    if Backend.rpm_ostree?
      UI.blank
      $stdout.puts UI.paint(UI::BOLD, UI::C_PURPLE, '  ▸ LAYERED RPM PACKAGES')
      layered = RpmOstree.list_layered
      if layered.empty?
        UI.note 'No layered packages installed.'
      else
        layered.each_slice(4) do |group|
          $stdout.puts '      ' + group.map { |p| UI.paint(UI::C_LGREY, p) }.join('  ')
        end
      end
    end

    # ── Flatpak summary ──────────────────────────────────────────────────
    if Backend.flatpak?
      UI.blank
      $stdout.puts UI.paint(UI::BOLD, UI::C_PURPLE, '  ▸ FLATPAK  ') +
                   UI.backend_badge('flatpak')
      fps = Flatpak.list
      if fps.empty?
        UI.note 'No Flatpak apps installed.'
      else
        UI.note "#{fps.size} app(s) installed. Run #{UI.paint(UI::C_CYAN, UI::BOLD, 'lpm flatpak list')} for details."
      end
      updates = Flatpak.list_updates
      UI.info "#{updates.size} update(s) available." unless updates.empty?
    end

    # ── Container summary ─────────────────────────────────────────────────
    if Distrobox.available?
      UI.blank
      $stdout.puts UI.paint(UI::BOLD, UI::C_PURPLE, '  ▸ CONTAINERS  ') +
                   UI.backend_badge(Distrobox.backend.to_s.tr('_', ''))
      boxes = Distrobox.list
      if boxes.empty?
        UI.note 'No containers found.'
      else
        boxes.each do |b|
          status_color = b[:status]&.match?(/up|running/i) ? UI::C_GREEN : UI::C_GREY
          $stdout.puts "      #{UI.paint(UI::BOLD, UI::C_MAGENTA, (b[:name] || '—').ljust(20))}  " \
                       "#{UI.paint(status_color, b[:status] || '—')}"
        end
      end
    end

    UI.blank
  end

  # ══════════════════════════════════════════════════════════════════════════
  # UPGRADE
  # ══════════════════════════════════════════════════════════════════════════
  def self.cmd_upgrade
    UI.section 'Upgrade System Image', icon: '↑'
    UI.info "Pulling latest image via #{UI.backend_badge(Backend.name)}…"
    UI.blank

    ok = if Backend.bootc?
    Spinner.stream('bootc upgrade', 'bootc upgrade')
  else
    Spinner.stream('rpm-ostree upgrade', 'rpm-ostree upgrade')
  end

  UI.blank
  if ok
    UI.success 'Image staged successfully!'
    UI.reboot_notice
  else
    UI.error 'Upgrade failed. Check output above.'
    exit 1
  end
end

# ══════════════════════════════════════════════════════════════════════════
# CHECK
# ══════════════════════════════════════════════════════════════════════════
def self.cmd_check
  UI.section 'Check for Updates', icon: '⟳'

  ok = avail = out = nil
  Spinner.run("Querying registry via #{Backend.name}…") do
    ok, avail, out, = Backend.bootc? ? Bootc.check : RpmOstree.check
    true
  end

  UI.blank
  if avail
    UI.success 'Update available! Run lpm upgrade to fetch it.'
  else
    UI.info 'System is up-to-date.'
  end

  unless out.to_s.empty?
    UI.blank
    $stdout.puts UI.paint(UI::DIM, UI::C_GREY, out.gsub(/^/, '    '))
  end
  UI.blank
end

# ══════════════════════════════════════════════════════════════════════════
# SWITCH (bootc only)
# ══════════════════════════════════════════════════════════════════════════
def self.cmd_switch(args)
  UI.section 'Switch Base Image', icon: '⇄'

  unless Backend.bootc?
    UI.error 'Image switching is only supported with bootc.'
    UI.note  'rpm-ostree uses rebase instead. Use: rpm-ostree rebase <ref>'
    exit 1
  end

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
               ['Transport',    transport || 'registry (default)'],
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

  ok = Spinner.stream('bootc switch',
                      "bootc switch #{image}#{transport ? " --transport #{transport}" : ''}")

  UI.blank
  if ok
    UI.success "Switched to #{image}"
    UI.reboot_notice
  else
    UI.error 'Switch failed. Check output above.'
    exit 1
  end
end

# ══════════════════════════════════════════════════════════════════════════
# ROLLBACK
# ══════════════════════════════════════════════════════════════════════════
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
    ok, _, err = Backend.bootc? ? Bootc.rollback : RpmOstree.rollback
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

# ══════════════════════════════════════════════════════════════════════════
# REBOOT
# ══════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════
# PKG (rpm-ostree layer commands)
# ══════════════════════════════════════════════════════════════════════════
def self.cmd_pkg(args)
  unless Backend.rpm_ostree?
    UI.error 'lpm pkg commands require rpm-ostree (not available on this system).'
    UI.note  'On bootc-based systems, use container images or Flatpak instead.'
    exit 1
  end

  sub = args.shift&.downcase
  case sub
  when 'install', 'add', 'i'
    pkgs = args
    if pkgs.empty?
      UI.error 'Specify at least one package name.'
      UI.step  'Usage: lpm pkg install <pkg1> [pkg2] …'
      exit 1
    end
    UI.section "Install RPM Layer: #{pkgs.join(', ')}", icon: '+'
    UI.info "Layering packages onto the base image via rpm-ostree…"
    UI.blank
    ok = Spinner.stream('rpm-ostree install', "rpm-ostree install -y #{pkgs.join(' ')}")
    UI.blank
    if ok
      UI.success "Packages layered: #{pkgs.join(', ')}"
      UI.reboot_notice
    else
      UI.error 'Install failed.'
      exit 1
    end

  when 'remove', 'uninstall', 'rm', 'r'
    pkgs = args
    if pkgs.empty?
      UI.error 'Specify at least one package name.'
      UI.step  'Usage: lpm pkg remove <pkg1> [pkg2] …'
      exit 1
    end
    UI.section "Remove RPM Layer: #{pkgs.join(', ')}", icon: '−'
    unless UI.confirm("Remove layered package(s): #{pkgs.join(', ')}?", default: false)
      UI.warn 'Aborted.'
      UI.blank
      return
    end
    UI.blank
    ok = Spinner.stream('rpm-ostree uninstall', "rpm-ostree uninstall -y #{pkgs.join(' ')}")
    UI.blank
    if ok
      UI.success "Removed: #{pkgs.join(', ')}"
      UI.reboot_notice
    else
      UI.error 'Removal failed.'
      exit 1
    end

  when 'list', 'ls', 'l'
    UI.section 'Layered RPM Packages', icon: '◉'
    layered = nil
    Spinner.run('Reading layered package list…') { layered = RpmOstree.list_layered; true }
    UI.blank
    if layered.empty?
      UI.info 'No layered packages installed.'
    else
      UI.note "#{layered.size} package(s) layered on top of base image:"
      UI.blank
      layered.each_slice(3) do |grp|
        $stdout.puts '    ' + grp.map { |p| UI.paint(UI::C_WHITE, p.ljust(24)) }.join
      end
    end
    UI.blank

  else
    UI.error sub ? "Unknown pkg subcommand: '#{sub}'" : 'Missing subcommand.'
    UI.blank
    $stdout.puts UI.paint(UI::C_LGREY, "  Subcommands: install, remove, list\n")
    exit 1
  end
end

# ══════════════════════════════════════════════════════════════════════════
# FLATPAK
# ══════════════════════════════════════════════════════════════════════════
def self.cmd_flatpak(args)
  unless Backend.flatpak?
    UI.error 'Flatpak is not installed on this system.'
    UI.step  'Install it with: lpm pkg install flatpak  (then reboot)'
    exit 1
  end

  sub = args.shift&.downcase
  case sub
  when 'list', 'ls', 'l', nil
    UI.section 'Installed Flatpak Apps', icon: '◈'
    apps = nil
    Spinner.run('Fetching Flatpak app list…') { apps = Flatpak.list; true }
    UI.blank
    if apps.empty?
      UI.info 'No Flatpak apps installed.'
    else
      UI.table(
        %w[Application Name Version Installation],
        apps.map { |a| [a[:app_id], a[:name], a[:version], a[:installation]] }
      )
    end
    UI.blank

  when 'install', 'add', 'i'
    app_id = args.shift
    unless app_id
      UI.error 'Specify a Flatpak application ID.'
      UI.step  'Usage: lpm flatpak install <app.id>'
      exit 1
    end
    remote = args.include?('--remote') ? args[args.index('--remote') + 1] : 'flathub'
    UI.section "Flatpak Install: #{app_id}", icon: '+'
    UI.blank
    ok = Spinner.stream("flatpak install #{app_id}",
                        "flatpak install --user -y #{remote} #{app_id}")
    UI.blank
    ok ? UI.success("Installed #{app_id}") : (UI.error('Install failed.'); exit 1)

  when 'remove', 'uninstall', 'rm', 'r'
    app_id = args.shift
    unless app_id
      UI.error 'Specify a Flatpak application ID.'
      UI.step  'Usage: lpm flatpak remove <app.id>'
      exit 1
    end
    UI.section "Flatpak Remove: #{app_id}", icon: '−'
    unless UI.confirm("Remove Flatpak app: #{app_id}?", default: false)
      UI.warn 'Aborted.'
      UI.blank
      return
    end
    UI.blank
    ok = Spinner.stream("flatpak uninstall #{app_id}",
                        "flatpak uninstall --user -y #{app_id}")
    UI.blank
    ok ? UI.success("Removed #{app_id}") : (UI.error('Removal failed.'); exit 1)

  when 'update', 'upgrade', 'up'
    app_id = args.first&.match?(/--/) ? nil : args.first
    UI.section 'Update Flatpak Apps', icon: '↑'
    UI.blank
    cmd_str = app_id ? "flatpak update --user -y #{app_id}" : 'flatpak update --user -y'
    ok = Spinner.stream('flatpak update', cmd_str)
    UI.blank
    ok ? UI.success('Flatpak apps updated!') : (UI.error('Update failed.'); exit 1)

  when 'search', 'find', 'q'
    query = args.join(' ')
    if query.empty?
      UI.error 'Specify a search query.'
      UI.step  'Usage: lpm flatpak search <query>'
      exit 1
    end
    UI.section "Flatpak Search: #{query}", icon: '⌕'
    results = nil
    Spinner.run("Searching Flathub for '#{query}'…") { results = Flatpak.search(query); true }
    UI.blank
    if results.empty?
      UI.info 'No results found.'
    else
      UI.table(
        %w[Application Name Version Description],
        results.first(10).map { |r| [r[:app_id], r[:name], r[:version], r[:description].to_s[0, 40]] }
      )
    end
    UI.blank

  when 'cleanup', 'clean', 'prune'
    UI.section 'Flatpak Cleanup', icon: '✦'
    UI.info 'Removing unused Flatpak runtimes and extensions…'
    UI.blank
    ok = Spinner.stream('flatpak cleanup', 'flatpak uninstall --user -y --unused')
    UI.blank
    ok ? UI.success('Cleanup complete.') : UI.warn('Cleanup encountered issues.')

  when 'remotes'
    UI.section 'Flatpak Remotes', icon: '◉'
    remotes = Flatpak.remotes
    if remotes.empty?
      UI.info 'No remotes configured.'
    else
      remotes.each { |r| UI.step r }
    end
    UI.blank

  else
    UI.error "Unknown flatpak subcommand: '#{sub}'"
    UI.blank
    $stdout.puts UI.paint(UI::C_LGREY,
                          "  Subcommands: list, install, remove, update, search, cleanup, remotes\n")
    exit 1
  end
end

# ══════════════════════════════════════════════════════════════════════════
# BOX (distrobox / toolbox)
# ══════════════════════════════════════════════════════════════════════════
def self.cmd_box(args)
  unless Distrobox.available?
    UI.error 'Neither distrobox nor toolbox is installed on this system.'
    UI.step  'Install distrobox: lpm pkg install distrobox'
    exit 1
  end

  backend_label = Distrobox.backend.to_s.tr('_', '')
  sub           = args.shift&.downcase

  case sub
  when 'list', 'ls', 'l', nil
    UI.section "Containers  #{UI.backend_badge(backend_label)}", icon: '□'
    boxes = nil
    Spinner.run("Listing #{backend_label} containers…") { boxes = Distrobox.list; true }
    UI.blank
    if boxes.empty?
      UI.info 'No containers found.'
    else
      UI.table(
        ['Name', 'Status', 'Image / ID'],
        boxes.map { |b| [b[:name] || '—', b[:status] || '—', b[:image] || b[:id] || '—'] }
      )
    end
    UI.blank

  when 'create', 'new', 'c'
    name  = args.shift
    image = args.shift
    unless name
      UI.error 'Specify a container name.'
      UI.step  'Usage: lpm box create <name> [image]'
      exit 1
    end
    UI.section "Create Container: #{name}", icon: '+'
    UI.kv_table([
                 ['Name',  name],
                 ['Image', image || 'default'],
                 ])
    UI.blank
    ok = Spinner.stream("#{backend_label} create #{name}",
                        image ? "#{Distrobox.bin} create --name #{name} --image #{image}"
                       : "#{Distrobox.bin} create --name #{name}")
    UI.blank
    ok ? UI.success("Container '#{name}' created.") : (UI.error('Creation failed.'); exit 1)

  when 'enter', 'e', 'shell'
    name = args.shift
    unless name
      UI.error 'Specify a container name.'
      UI.step  'Usage: lpm box enter <name>'
      exit 1
    end
    UI.section "Enter: #{name}", icon: '→'
    UI.info "Entering container '#{name}'… (type 'exit' to return)"
    UI.blank
    Distrobox.enter(name)

  when 'remove', 'rm', 'delete', 'd'
    name = args.shift
    unless name
      UI.error 'Specify a container name.'
      UI.step  'Usage: lpm box remove <name>'
      exit 1
    end
    UI.section "Remove Container: #{name}", icon: '−'
    unless UI.confirm("Remove container '#{name}'?", default: false)
      UI.warn 'Aborted.'
      UI.blank
      return
    end
    UI.blank
    ok = Spinner.stream("remove #{name}", nil) do
      Distrobox.remove(name)
    end
    ok, = Distrobox.remove(name)
    ok ? UI.success("Container '#{name}' removed.") : (UI.error('Removal failed.'); exit 1)

  when 'upgrade', 'update', 'up'
    UI.section 'Upgrade All Containers', icon: '↑'
    unless Distrobox.backend == :distrobox
      UI.error 'Container upgrade is only supported with distrobox.'
      exit 1
    end
    UI.blank
    ok = Spinner.stream('distrobox upgrade --all', 'distrobox upgrade --all')
    UI.blank
    ok ? UI.success('All containers upgraded.') : UI.warn('Some upgrades may have failed.')

  when 'export', 'exp'
    container = args.shift
    type      = args.shift  # 'app' or 'bin'
    target    = args.shift

    unless container && type && target
      UI.error 'Missing arguments.'
      UI.step  'Usage: lpm box export <container> app <app-name>'
      UI.step  '       lpm box export <container> bin <bin-path>'
      exit 1
    end

    UI.section "Export from #{container}", icon: '↗'
    UI.blank

    ok, = case type.downcase
  when 'app'  then Distrobox.export_app(container, target)
  when 'bin'  then Distrobox.export_bin(container, target)
  else
    UI.error "Unknown export type '#{type}'. Use 'app' or 'bin'."
    exit 1
  end

  ok ? UI.success("Exported #{type} '#{target}' from '#{container}'.")
  : (UI.error('Export failed.'); exit 1)

else
  UI.error sub ? "Unknown box subcommand: '#{sub}'" : 'Missing subcommand.'
  UI.blank
  $stdout.puts UI.paint(UI::C_LGREY,
                        "  Subcommands: list, create, enter, remove, upgrade, export\n")
  exit 1
end
  end

  # ══════════════════════════════════════════════════════════════════════════
  # VERSION
  # ══════════════════════════════════════════════════════════════════════════
  def self.cmd_version
    lines = [
      UI.paint(UI::BOLD, UI::C_WHITE, "  #{LPM::NAME}  ") +
    UI.paint(UI::BOLD, UI::C_MAGENTA, "v#{LPM::VERSION}"),
      UI.paint(UI::C_GREY, "  #{LPM::DISTRO} Package Manager"),
      '',
      UI.paint(UI::DIM, UI::C_GREY, '  Backends detected:'),
      ]

    # Image backend
    backend_name = Backend.bootc? ? 'bootc' : 'rpm-ostree'
    lines << "    #{UI.backend_badge(backend_name)}  #{UI.paint(UI::C_GREEN, UI::BOLD, '✔ available')}"

    # Optional backends
    {
      'flatpak'  => Backend.flatpak?,
      'distrobox' => Backend.distrobox?,
      'toolbox'  => Backend.toolbox?,
      }.each do |name, present|
      status = present ? UI.paint(UI::C_GREEN, UI::BOLD, '✔ available')
      : UI.paint(UI::C_GREY,  UI::DIM,  '✖ not found')
      lines << "    #{UI.backend_badge(name)}  #{status}"
    end

    lines << ''
    lines << UI.paint(UI::DIM, UI::C_GREY, '  github.com/legendaryos/lpm')

    UI.box(lines, title: ' VERSION ', color: UI::C_MAGENTA, width: 56)
  end

  # ══════════════════════════════════════════════════════════════════════════
  # HELP
  # ══════════════════════════════════════════════════════════════════════════
  def self.cmd_help
    $stdout.puts HELP_TEXT
    UI.blank
  end
end
