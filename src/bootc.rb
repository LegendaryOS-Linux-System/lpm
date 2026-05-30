require 'json'
require 'open3'

module Bootc
  BIN = 'bootc'

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
    ok, out, err = run('status', '--format', 'json')
    return { error: "bootc status failed: #{err.empty? ? out : err}" } unless ok

    begin
      raw = JSON.parse(out)
      booted   = raw.dig('status', 'booted')   || {}
      staged   = raw.dig('status', 'staged')   || {}
      rollback = raw.dig('status', 'rollback') || {}

      b_img    = booted.dig('image', 'image', 'image')   || booted.dig('image', 'image') || '—'
      b_ver    = booted.dig('image', 'version')          || '—'
      b_ts     = booted.dig('image', 'timestamp')        || '—'
      b_digest = booted.dig('image', 'imageDigest')      || '—'
      b_digest = b_digest[0, 28] + '…' if b_digest.length > 28

      s_img    = staged.dig('image', 'image', 'image')   || staged.dig('image', 'image')
      s_ver    = staged.dig('image', 'version')          || '—'
      s_digest = staged.dig('image', 'imageDigest')      || '—'
      s_digest = s_digest[0, 28] + '…' if s_digest.length > 28

      r_img    = rollback.dig('image', 'image', 'image') || rollback.dig('image', 'image')
      r_ver    = rollback.dig('image', 'version')        || '—'

      {
        backend:        'bootc',
        booted_image:   b_img,
        booted_ver:     b_ver,
        booted_ts:      b_ts,
        booted_digest:  b_digest,
        staged_image:   s_img,
        staged_ver:     s_ver,
        staged_digest:  s_digest,
        rollback_image: r_img,
        rollback_ver:   r_ver,
        staged?:        !staged.empty?,
        rollback?:      !rollback.empty?,
        raw:            raw
      }
    rescue JSON::ParserError => e
      { error: "JSON parse error: #{e.message}" }
    end
  end

  def self.upgrade(&block)    = run_stream('upgrade', &block)
  def self.switch(image, transport: nil, &block)
    args = ['switch', image]
    args += ['--transport', transport] if transport
    run_stream(*args, &block)
  end
  def self.rollback           = run('rollback')
  def self.reboot             = run('systemctl', 'reboot')
  def self.check
    ok, out, err = run('upgrade', '--check')
    avail = out.match?(/update available|newer image/i)
    [ok, avail, out, err]
  end
end
