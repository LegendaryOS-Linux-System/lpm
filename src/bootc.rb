require 'json'
require 'open3'

module Bootc
  BOOTC = 'bootc'

  # ── Low-level helpers ────────────────────────────────────────────────────

  # Run bootc and return [success, stdout, stderr]
  def self.run(*args)
    cmd = [BOOTC, *args.map(&:to_s)]
    stdout, stderr, status = Open3.capture3(*cmd)
    [status.success?, stdout.strip, stderr.strip]
  end

  # Run bootc with live streaming (for upgrade/switch which are verbose)
  def self.run_stream(*args)
    cmd = "#{BOOTC} #{args.join(' ')} 2>&1"
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

  # Returns a hash with parsed bootc status fields
  def self.status
    ok, out, err = run('status', '--format', 'json')
    unless ok
      return { error: "bootc status failed: #{err.empty? ? out : err}" }
    end

    begin
      raw = JSON.parse(out)
      spec_image  = raw.dig('spec', 'image', 'image')     || 'unknown'
      booted      = raw.dig('status', 'booted')           || {}
      staged      = raw.dig('status', 'staged')           || {}
      rollback    = raw.dig('status', 'rollback')         || {}

      b_img   = booted.dig('image', 'image', 'image')    || booted.dig('image', 'image') || 'unknown'
      b_ver   = booted.dig('image', 'version')           || '—'
      b_ts    = booted.dig('image', 'timestamp')         || '—'
      b_digest = booted.dig('image', 'imageDigest')      || '—'
      b_digest = b_digest[0, 24] + '…' if b_digest.length > 24

      s_img   = staged.dig('image', 'image', 'image')    || staged.dig('image', 'image')
      s_ver   = staged.dig('image', 'version')           || '—'
      s_digest = staged.dig('image', 'imageDigest')      || '—'
      s_digest = s_digest[0, 24] + '…' if s_digest.length > 24

      r_img   = rollback.dig('image', 'image', 'image')  || rollback.dig('image', 'image')
      r_ver   = rollback.dig('image', 'version')         || '—'

      {
        spec_image:   spec_image,
        booted_image: b_img,
        booted_ver:   b_ver,
        booted_ts:    b_ts,
        booted_digest: b_digest,
        staged_image: s_img,
        staged_ver:   s_ver,
        staged_digest: s_digest,
        rollback_image: r_img,
        rollback_ver:  r_ver,
        staged?:       !staged.empty?,
        rollback?:     !rollback.empty?,
        raw:           raw
      }
    rescue JSON::ParserError => e
      { error: "Could not parse bootc status JSON: #{e.message}" }
    end
  end

  # ── Upgrade ──────────────────────────────────────────────────────────────

  def self.upgrade(&block)
    run_stream('upgrade', &block)
  end

  # ── Switch ───────────────────────────────────────────────────────────────

  def self.switch(image, transport: nil, &block)
    args = ['switch', image]
    args += ['--transport', transport] if transport
    run_stream(*args, &block)
  end

  # ── Rollback ─────────────────────────────────────────────────────────────

  def self.rollback
    run('rollback')
  end

  # ── Reboot ───────────────────────────────────────────────────────────────

  def self.reboot
    run('systemctl', 'reboot')
  end

  # ── Fetch only (stage without applying) ──────────────────────────────────

  def self.fetch(&block)
    run_stream('upgrade', '--check', &block)
  end

  # ── Check for updates (no download) ──────────────────────────────────────

  def self.check
    ok, out, err = run('upgrade', '--check')
    # bootc --check exits 0 even when there's nothing; parse output
    update_available = out.match?(/update available|newer image/i)
    [ok, update_available, out, err]
  end
end
