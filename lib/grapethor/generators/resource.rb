require 'thor/group'
require 'active_support/inflector'

module Grapethor
  class Resource < Thor::Group
    include Thor::Actions
    include Grapethor::Utils

    attr_reader :api_version,
                :app_path,
                :res_name,
                :res_query,
                :res_desc

    namespace :resource

    def self.exit_on_failure?
      true
    end

    def self.source_root
      File.join(__dir__, '..')
    end


    argument :name, type: :string,
                    desc: "Resource name"


    class_option :path,    aliases: '-p',
                           type: :string,
                           default: '.',
                           desc: 'Relative path to application directory'

    class_option :version, aliases: '-v',
                           type: :string,
                           default: 'v1',
                           desc: 'API version tag'

    class_option :query,   aliases: '-q',
                           type: :hash,
                           default: {},
                           desc: 'Request query params (model attributes)'


    def parse_args_and_opts
      @res_name    = name.downcase.singularize
      @res_query   = options[:query].delete_if { |k, v| k == 'id' }.map { |k, v| [k, v.downcase] }.to_h
      @api_version = options[:version].downcase
      @app_path    = options[:path]
    end


    def validate_target_api
      unless api_version_exists?
        alert "API version '#{api_version}' does not exist!"
        exit
      end
    end


    def create_resource
      report("Creating new resource...") do
        directory "templates/resource", "#{app_path}"
        directory "templates/resource_#{app_test_framework}", "#{app_path}"

        insert_into_file "#{app_path}/api/#{api_version}/base.rb",
                         "\s\s\s\smount API#{api_version}::#{res_name.classify.pluralize}\n",
                         before: "\s\s\s\s# mount API#{api_version}::<ResourceOrEndpointClass>\n"
      end
    end


    private

    def api_version_exists?
      Dir.exist?("#{app_path}/api/#{api_version}")
    end

    def res_migration
      "#{Time.now.strftime("%Y%m%d%H%M%S")}_create_#{res_name.pluralize}"
    end

    def res_name_plural
      res_name.pluralize
    end
  end
end