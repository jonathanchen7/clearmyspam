module Views
  class StimulusData
    include ActionView::Helpers::TagHelper

    def initialize(controllers: [], actions: {}, targets: {}, values: {}, params: {}, include_controller: false)
      validate_controllers(Array(controllers))
      validate_actions(actions)
      validate_targets(targets)
      validate_nested_hash(values, "values")
      validate_nested_hash(params, "params")

      @controllers = Array(controllers)
      @actions = actions
      @targets = targets
      @values = values
      @params = params
      @include_controller = include_controller
    end

    def erb_attributes
      {}.tap do |attrs|
        attrs["controller"] = controllers.join(" ") if include_controller && controllers.any?
        attrs["action"] = format_actions if actions.any?
        attrs.merge!(format_targets)
        attrs.merge!(format_values)
        attrs.merge!(format_params)
      end
    end

    def html_attributes
      tag.attributes(data: erb_attributes)
    end

    private

    def format_actions
      actions.map do |event, nested_actions|
        Array(nested_actions).map { |action| "#{event}->#{action}" }
      end.join(" ")
    end

    def format_targets
      targets.transform_keys { |controller| "#{controller}-target" }
    end

    def format_values
      format_controller_specific_attributes(values, "value")
    end

    def format_params
      format_controller_specific_attributes(params, "param")
    end

    def format_controller_specific_attributes(data, suffix)
      data.each_with_object({}) do |(controller, attributes), result|
        attributes.each { |key, value| result["#{controller}-#{key}-#{suffix}"] = value }
      end
    end

    # Validations

    def validate_controllers(controllers)
      unless controllers.is_a?(Array) && controllers.all? { |c| c.is_a?(String) && !c.empty? }
        raise ArgumentError, "controllers must be an array of non-empty strings"
      end
    end

    def validate_actions(actions)
      unless actions.is_a?(Hash) && actions.all? do |event, nested_actions|
        event.is_a?(String) && Array(nested_actions).all? { |a| a.match?(/\A[\w-]+#\w+\z/) }
      end
        raise ArgumentError, "actions must be a hash with format: { 'event' => 'controller#method' }"
      end
    end

    def validate_targets(targets)
      unless targets.is_a?(Hash) && targets.all? { |controller, target| controller.is_a?(String) && target.is_a?(String) }
        raise ArgumentError, "targets must be a hash with format: { 'controller' => 'target1' }"
      end
    end

    def validate_nested_hash(data, field_name)
      unless data.is_a?(Hash) && data.all? { |controller, attributes| controller.is_a?(String) && attributes.is_a?(Hash) }
        raise ArgumentError, "#{field_name} must be a hash with format: { 'controller' => { 'key' => 'value' } }"
      end
    end

    attr_reader :controllers, :actions, :targets, :values, :params, :include_controller
  end
end
