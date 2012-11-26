require "rubygems"

require "open-uri"
require "sinatra"
require "thin"
require "haml"
require "json"
require "i18n"
require "active_support/core_ext"
require "redcarpet"
require "thor"
require "builder"

require "gdash/version"
require "gdash/configuration"

require "gdash/data/point"
require "gdash/data/source"
require "gdash/data/sources/ganglia"
require "gdash/data/sources/cacti"
require "gdash/data/set"

require 'gdash/doc'
require 'gdash/window'
require 'gdash/windows'
require 'gdash/data_center'
require 'gdash/widget'
require 'gdash/named'
require 'gdash/cacti_graph'
require 'gdash/nagios'
require 'gdash/dashboard'
require 'gdash/section'
require 'gdash/helper'
require 'gdash/app'

require "gdash/cli"

module GDash
  class << self
    def config *args
      @config ||= Configuration.new(*args)
      yield config if block_given?
      @config
    end

    def init! options = {}
      dashfile = options[:dashfile] || File.expand_path("Dashfile", FileUtils.pwd)
      load dashfile
      load config.dashboards
    end
  end
end