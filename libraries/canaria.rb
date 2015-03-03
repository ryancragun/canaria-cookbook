require 'digest/md5'

# Determine if a node is a canary
module Canaria
  def self.canary?(unique_string, percent, overrides = [])
    return true if overrides.include?(unique_string)
    return false if percent.to_i == 0
    Digest::MD5.hexdigest(unique_string).to_s.hex % 100 <= percent.to_i
  end

  def self.chef_environment(node, chef_env)
    begin
      Chef::Environment.load(chef_env)
    rescue Net::HTTPServerException => e
      msg = 'Chef Environment error: '
      if e.response.code.to_s == '404'
        msg << "#{chef_env} does not exist, cannot change."
      else
        msg << "#{chef_env} raised #{e.message}"
      end
      Chef::Log.error(msg)
      raise
    end

    node.chef_environment(chef_env)
  end

  # DSL module we'll mix into the Chef DSL
  module DSL
    def canary?
      Canaria.canary?(node['fqdn'],
                      node['canaria']['percentage'],
                      node['canaria']['overrides'])
    end

    # rubocop:disable AccessorMethodName
    def set_chef_environment(chef_env)
      Canaria.chef_environment(node, chef_env)
    end
    # rubocop:enable AccessorMethodName
  end
end

if defined?(Chef)
  Chef::Recipe.send(:include, Canaria::DSL)
  Chef::Provider.send(:include, Canaria::DSL)
  Chef::Resource.send(:include, Canaria::DSL)
  Chef::ResourceDefinition.send(:include, Canaria::DSL)
end
