require 'json'
require 'open3'

module RpmOstree
    BIN = 'rpm-ostree'

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

    # ── Status ───────────────────────────────────────────────────────────────
    def self.status
        ok, out, err = run('status', '--json')
        return { error: "rpm-ostree status failed: #{err.empty? ? out : err}" } unless ok

        begin
            raw = JSON.parse(out)
            deployments = raw['deployments'] || []
            booted      = deployments.find { |d| d['booted'] } || {}
            pending     = deployments.find { |d| d['staged'] || (!d['booted'] && deployments.index(d) < deployments.index(booted || 0)) }
            rollback    = deployments.reject { |d| d['booted'] || d == pending }.first

            checksum  = booted['checksum'] || '—'
            short_cs  = checksum.length > 14 ? checksum[0, 14] + '…' : checksum

            {
                backend:        'rpm-ostree',
                booted_image:   booted['origin'] || booted['osname'] || '—',
                booted_ver:     booted['version'] || '—',
                booted_ts:      booted['timestamp'] ? Time.at(booted['timestamp']).to_s : '—',
                booted_digest:  short_cs,
                booted_pkgs:    booted['requested-packages']&.join(', ') || '—',
                booted_layered: booted['packages']&.reject { |p| booted['base-removals']&.include?(p) } || [],
                staged_image:   pending&.dig('origin'),
                staged_ver:     pending&.dig('version') || '—',
                staged_digest:  (pending&.dig('checksum') || '')[0, 14] + (pending ? '…' : ''),
                rollback_image: rollback&.dig('origin') || rollback&.dig('osname'),
                rollback_ver:   rollback&.dig('version') || '—',
                staged?:        !pending.nil?,
                rollback?:      !rollback.nil?,
                raw:            raw
            }
        rescue JSON::ParserError => e
            { error: "JSON parse error: #{e.message}" }
        end
    end

    # ── Upgrade ───────────────────────────────────────────────────────────────
    def self.upgrade(&block)
        run_stream('upgrade', &block)
    end

    # ── Check ────────────────────────────────────────────────────────────────
    def self.check
        ok, out, err = run('upgrade', '--check')
        avail = !out.match?(/No updates available/i) && ok
        [ok, avail, out, err]
    end

    # ── Layer packages ────────────────────────────────────────────────────────
    def self.install(*pkgs, &block)
        run_stream('install', *pkgs, &block)
    end

    def self.uninstall(*pkgs, &block)
        run_stream('uninstall', *pkgs, &block)
    end

    def self.override_replace(*pkgs, &block)
        run_stream('override', 'replace', *pkgs, &block)
    end

    def self.override_reset(&block)
        run_stream('override', 'reset', '--all', &block)
    end

    # ── Pin / Unpin deployments ───────────────────────────────────────────────
    def self.pin(index = 0)
        run('deploy', '--index', index.to_s, '--pin')
    end

    def self.rollback
        run('rollback')
    end

    def self.reboot
        run('systemctl', 'reboot')
    end

    # ── List installed layered packages ─────────────────────────────────────
    def self.list_layered
        ok, out, = run('status')
        return [] unless ok
        lines = out.split("\n").select { |l| l.match?(/LayeredPackages|RequestedPackages/i) }
        lines.flat_map { |l| l.split(':').last.to_s.split }.uniq
    end
end
