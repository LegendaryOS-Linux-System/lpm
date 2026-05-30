require 'open3'

module Flatpak
    BIN = 'flatpak'

    def self.available?
        Backend.flatpak?
    end

    def self.run(*args)
        cmd = [BIN, *args.map(&:to_s)]
        stdout, stderr, status = Open3.capture3(*cmd)
        [status.success?, stdout.strip, stderr.strip]
    end

    def self.run_stream(*args, &block)
        cmd = "#{BIN} #{args.join(' ')} 2>&1"
        output = []
        IO.popen(cmd, 'r') do |io|
            io.each_line do |line|
                output << line.chomp
                yield line.chomp if block_given?
            end
        end
        [$?.success?, output]
    end

    # ── List installed ────────────────────────────────────────────────────────
    def self.list(system: false)
        scope = system ? '--system' : '--user'
        ok, out, = run('list', scope, '--columns=application,name,version,size,installation')
        return [] unless ok
        out.split("\n").map do |line|
            parts = line.split("\t")
            {
                app_id:       parts[0] || '—',
                name:         parts[1] || '—',
                version:      parts[2] || '—',
                size:         parts[3] || '—',
                installation: parts[4] || '—',
                }
        end
    end

    def self.list_updates
        ok, out, = run('remote-ls', '--updates', '--columns=application,name,version')
        return [] unless ok
        out.split("\n").map do |line|
            parts = line.split("\t")
            { app_id: parts[0], name: parts[1], version: parts[2] }
        end
    end

    # ── Install ───────────────────────────────────────────────────────────────
    def self.install(app_id, remote: 'flathub', system: false, &block)
        scope = system ? '--system' : '--user'
        run_stream('install', scope, '-y', remote, app_id, &block)
    end

    # ── Uninstall ─────────────────────────────────────────────────────────────
    def self.uninstall(app_id, system: false, &block)
        scope = system ? '--system' : '--user'
        run_stream('uninstall', scope, '-y', app_id, &block)
    end

    # ── Update ────────────────────────────────────────────────────────────────
    def self.update(app_id: nil, system: false, &block)
        scope = system ? '--system' : '--user'
        args  = ['update', '-y', scope]
        args << app_id if app_id
        run_stream(*args, &block)
    end

    # ── Search ────────────────────────────────────────────────────────────────
    def self.search(query)
        ok, out, = run('search', '--columns=application,name,description,version', query)
        return [] unless ok
        out.split("\n").first(20).map do |line|
            parts = line.split("\t")
            { app_id: parts[0], name: parts[1], description: parts[2], version: parts[3] }
        end
    end

    # ── Remotes ────────────────────────────────────────────────────────────────
    def self.remotes(system: false)
        scope = system ? '--system' : '--user'
        ok, out, = run('remotes', scope)
        return [] unless ok
        out.split("\n").map { |l| l.split.first }
    end

    def self.add_remote(name, url, system: false)
        scope = system ? '--system' : '--user'
        run('remote-add', scope, '--if-not-exists', name, url)
    end

    # ── Repair / cleanup ──────────────────────────────────────────────────────
    def self.repair(system: false, &block)
        scope = system ? '--system' : '--user'
        run_stream('repair', scope, &block)
    end

    def self.uninstall_unused(system: false, &block)
        scope = system ? '--system' : '--user'
        run_stream('uninstall', scope, '-y', '--unused', &block)
    end
end
