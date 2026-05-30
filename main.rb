#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, 'src')

require 'ui'
require 'bootc'
require 'rpm_ostree'
require 'flatpak'
require 'distrobox'
require 'backend'
require 'commands'
require 'spinner'

module LPM
  VERSION = '2.0.0'
  NAME    = 'lpm'
  DISTRO  = 'LegendaryOS'
end

UI.init
Commands.run(ARGV)
