# frozen_string_literal: true

require "test_helper"

module Views
  class StimulusDataTest < ActiveSupport::TestCase
    test "validations" do
      error_message = "controllers must be an array of non-empty strings"
      assert_raises(ArgumentError, match: error_message) do
        StimulusData.new(controllers: 5)
      end

      error_message = "actions must be a hash with format: { 'event' => 'controller#method' }"
      assert_raises(ArgumentError, match: error_message) do
        StimulusData.new(actions: { "click" => "invalid_format" })
      end

      error_message = "targets must be a hash with format: { 'controller' => 'target1' }"
      assert_raises(ArgumentError, match: error_message) do
        StimulusData.new(targets: { "animal" => ["cat"] })
      end

      error_message = "values must be a hash with format: { 'controller' => { 'key' => 'value' } }"
      assert_raises(ArgumentError, match: error_message) do
        StimulusData.new(values: { "animal" => "not_a_hash" })
      end

      error_message = "params must be a hash with format: { 'controller' => { 'key' => 'value' } }"
      assert_raises(ArgumentError, match: error_message) do
        StimulusData.new(params: { "animal" => "invalid" })
      end
    end

    test "#erb_attributes" do
      expected_result = {
        "controller" => "animal zoo",
        "action" => "click->animal#feed click->zoo#celebrate mouseover->zoo#open",
        "animal-target" => "cat",
        "zoo-target" => "enclosure",
        "animal-food-value" => "tuna",
        "animal-quantity-value" => "2",
        "zoo-capacity-value" => "50",
        "animal-time-param" => "now",
        "zoo-open-param" => "yes"
      }

      assert_equal expected_result, stimulus_data.erb_attributes
    end

    test "#html_attributes" do
      expected_result = 'data-controller="animal zoo" ' \
        "data-action=\"click-&gt;animal#feed click-&gt;zoo#celebrate mouseover-&gt;zoo#open\" " \
        "data-animal-target=\"cat\" " \
        "data-zoo-target=\"enclosure\" " \
        "data-animal-food-value=\"tuna\" " \
        "data-animal-quantity-value=\"2\" " \
        "data-zoo-capacity-value=\"50\" " \
        "data-animal-time-param=\"now\" " \
        "data-zoo-open-param=\"yes\""

      assert_equal expected_result, stimulus_data.html_attributes
    end

    private

    def stimulus_data
      StimulusData.new(
        controllers: %w[animal zoo],
        actions: { "click" => %w[animal#feed zoo#celebrate], "mouseover" => "zoo#open" },
        targets: { "animal" => "cat", "zoo" => "enclosure" },
        values: { "animal" => { "food" => "tuna", "quantity" => "2" }, "zoo" => { "capacity" => "50" } },
        params: { "animal" => { "time" => "now" }, "zoo" => { "open" => "yes" } },
        include_controller: true
      )
    end
  end
end
