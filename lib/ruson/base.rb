require 'json'
require 'active_support'
require 'active_support/core_ext'

require 'ruson/class/array'
require 'ruson/class/boolean'
require 'ruson/class/float'
require 'ruson/class/integer'
require 'ruson/class/time'

require 'ruson/converter'
require 'ruson/json'
require 'ruson/nilable'
require 'ruson/persistence'
require 'ruson/querying'
require 'ruson/value'

require 'ruson/error'

module Ruson
  class Base
    class << self
      def field(attr, options = {})
        instance_eval("attr_accessor :#{attr.to_s}")
        add_accessor attr.to_s, options
      end

      def enum(attr, values)
        define_enum_methods attr.to_s, values.map(&:to_sym)
        add_accessor attr.to_s
      end

      def accessors
        @accessors
      end

      private

      def define_enum_methods(name, values)
        instance_eval("attr_reader :#{name}")

        define_method "#{name}=" do |v|
          raise ArgumentError, "#{v} is not a valid #{name}" unless values.include? v.to_sym
          eval "@#{name} = :#{v.to_s}"
        end

        values.each do |v|
          define_method "#{v}?" do
            eval "@#{name} == :#{v.to_s}"
          end
        end
      end

      def add_accessor(name, options = {})
        options[:name] = options[:name].try(:to_sym) if options[:name]

        @accessors ||= {}
        @accessors.merge!({ name.to_sym => options })
      end
    end

    # ~~~~ Mixins ~~~~
    include Ruson::Converter
    include Ruson::Json
    include Ruson::Nilable
    include Ruson::Persistence
    include Ruson::Querying
    include Ruson::Value

    # ~~~~ Class Methods ~~~~
    def self.ensure_output_folder_is_defined
      return if Ruson.output_folder

      raise ArgumentError, 'No output folder defined. You can define it ' \
                           'using Ruson.output_folder = "/path/to/db/folder"'
    end

    # ~~~~ Instance Methods ~~~~
    def initialize(json, root_key: nil)
      params = get_hash_from_json(json)
      params = params[root_key.to_s] unless root_key.nil?

      init_attributes(self.class.accessors, params)
    end

    def to_hash
      res = convert_to_hash(self.class.accessors)

      res.inject({}) do |result, attributes|
        key, value = attributes
        accessor = self.class.accessors[key]
        if accessor && accessor.key?(:name)
          result[accessor[:name]] = value
        else
          result[key] = value
        end
        result
      end
    end

    def to_json(options = {})
      hash = to_hash

      options[:exclude].each { |key| hash.delete(key) } if options[:exclude]

      hash.to_json
    end

    private

    def cast_value(value, accessor_options, options = {})
      check_nilable(value, accessor_options)
      get_val(value, accessor_options)
    end

    def init_attributes(accessors, params)
      update_attributes(accessors, params)

      self.class.attr_accessor(:id)
      set_attribute(:id, params[:id]) if params && params[:id]
    end

    def set_attribute(attr_name, value)
      send("#{attr_name}=".to_sym, value)
    end

    def update_attributes(accessors, params)
      accessors.each do |key, options|
        value = params[options[:name]] || params[key] if params

        casted_value = cast_value(value, options)
        set_attribute(key, casted_value)
      end
    end
  end
end
