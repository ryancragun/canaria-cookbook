require 'digest/md5'

# Determine if a node is a canary
module Canaria
  def self.canary?(unique_string, percent, overrides = [])
    return true if overrides.include?(unique_string)
    return false if percent.to_i == 0
    Digest::MD5.hexdigest(unique_string).to_s.hex % 100 <= percent.to_i
  end

  # DSL module we'll mix into the Chef DSL
  module DSL
    def canary?
      Canaria.canary?(node['fqdn'],
                      node['canaria']['percentage'],
                      node['canaria']['overrides'])
    end
  end
end

if defined?(Chef)
  Chef::Recipe.send(:include, Canaria::DSL)
  Chef::Provider.send(:include, Canaria::DSL)
  Chef::Resource.send(:include, Canaria::DSL)
  Chef::ResourceDefinition.send(:include, Canaria::DSL)
end
