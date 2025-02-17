# frozen_string_literal: true

module Views
  class Tab
    attr_reader :id, :name, :stimulus_controller, :stimulus_action

    def initialize(id:, name:, stimulus_controller: nil, stimulus_action: "changeTab")
      @id = id
      @name = name
      @stimulus_controller = stimulus_controller
      @stimulus_action = stimulus_action
    end

    def stimulus_data
      if stimulus_controller && stimulus_action
        StimulusData.new(
          controllers: stimulus_controller,
          actions: { "click" => "#{stimulus_controller}##{stimulus_action}" },
          targets: { stimulus_controller => "tab" },
          values: { stimulus_controller => { "tab-id" => id } },
          params: { stimulus_controller => { "tab-id" => id } }
        )
      end
    end
  end
end
