require 'open3'
require 'json'

module Distrobox
    BIN_DISTROBOX = 'distrobox'
    BIN_TOOLBOX   = 'toolbox'

    def self.backend
        Backend.container_backend
    end

    def self.available?
        !backend.nil?
    end

    def self.bin
        case backend
        when :distrobox then BIN_DISTROBOX
        when :toolbox   then BIN_TOOLBOX
        else raise 'No container backend available'
        end
    end

    def self.run(*args)
        cmd = [bin, *args.map(&:to_s)]
        stdout, stderr, status = Open3.capture3(*cmd)
        [status.success?, stdout.strip, stderr.strip]
    end

    def self.run_stream(*args, &block)
        cmd = "#{bin} #{args.join(' ')} 2>&1"
        output = []
        IO.popen(cmd, 'r') do |io|
            io.each_line do |line|
                output << line.chomp
                yield line.chomp if block_given?
            end
        end
        [$?.success?, output]
    end

    # ── List containers ───────────────────────────────────────────────────────
    def self.list
        case backend
        when :distrobox
            ok, out, = run('list', '--no-color')
            return [] unless ok
            lines = out.split("\n").drop(1) # skip header
            lines.map do |l|
                parts = l.split('|').map(&:strip)
                { id: parts[0], name: parts[1], status: parts[2], image: parts[3] }
            end
        when :toolbox
            ok, out, = run('list', '--containers')
            return [] unless ok
            lines = out.split("\n").drop(1)
            lines.map do |l|
                parts = l.split.first(4)
                { id: parts[0], name: parts[1], created: parts[2], status: parts[3] }
            end
        else
            []
        end
    end

    # ── Create ────────────────────────────────────────────────────────────────
    def self.create(name, image: nil, &block)
        case backend
        when :distrobox
            args = ['create', '--name', name]
            args += ['--image', image] if image
            run_stream(*args, &block)
        when :toolbox
            args = ['create', '--container', name]
            args += ['--image', image] if image
            run_stream(*args, &block)
        end
    end

    # ── Enter ─────────────────────────────────────────────────────────────────
    def self.enter(name)
        case backend
        when :distrobox then system("#{BIN_DISTROBOX} enter #{name}")
        when :toolbox   then system("#{BIN_TOOLBOX} run --container #{name}")
        end
    end

    # ── Run command in container ──────────────────────────────────────────────
    def self.exec_in(name, *cmd, &block)
        case backend
        when :distrobox
            run_stream('enter', name, '--', *cmd, &block)
        when :toolbox
            run_stream('run', '--container', name, *cmd, &block)
        end
    end

    # ── Stop / Remove ─────────────────────────────────────────────────────────
    def self.stop(name, &block)
        case backend
        when :distrobox then run_stream('stop', name, '-Y', &block)
        when :toolbox   then run('rm', '--force', '--container', name)
        end
    end

    def self.remove(name, &block)
        case backend
        when :distrobox then run_stream('rm', name, '-f', &block)
        when :toolbox   then run_stream('rm', '--force', '--container', name, &block)
        end
    end

    # ── Export app from container ─────────────────────────────────────────────
    def self.export_app(container, app, &block)
        return [false, []] unless backend == :distrobox
        run_stream('enter', container, '--', 'distrobox-export', '--app', app, &block)
    end

    def self.export_bin(container, bin_path, &block)
        return [false, []] unless backend == :distrobox
        run_stream('enter', container, '--', 'distrobox-export', '--bin', bin_path,
                   '--export-path', "#{ENV['HOME']}/.local/bin", &block)
    end

    # ── Upgrade all containers ────────────────────────────────────────────────
    def self.upgrade_all(&block)
        return [false, []] unless backend == :distrobox
        run_stream('upgrade', '--all', &block)
    end

    # ── List images (distrobox only) ─────────────────────────────────────────
    def self.list_images
        return [] unless backend == :distrobox
        ok, out, = run('create', '--compatibility')
        return [] unless ok
        out.split("\n").map(&:strip).reject(&:empty?)
    end
end
