require 'rubygems'
require 'staticmatic'
require 'rena'
require 'activerdf_reddy'
require 'activerdf_rules'

require File.dirname(__FILE__) + '/ldontospec/base'
require File.dirname(__FILE__) + '/ldontospec/activerdf_hacks'
require File.dirname(__FILE__) + '/ldontospec/helpers'

Haml::Helpers.class_eval("include LDOntoSpec::Helpers")
