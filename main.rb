require_relative 'src/ui'
require_relative 'src/bootc'
require_relative 'src/commands'
require_relative 'src/spinner'

module LPM
  VERSION = '1.0.0'
  NAME    = 'lpm'
  DISTRO  = 'LegendaryOS'
end

UI.init
Commands.run(ARGV)
