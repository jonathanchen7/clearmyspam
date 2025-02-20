# frozen_string_literal: true

require "test_helper"

class ToastComponentTest < ActiveSupport::TestCase
  test "#initialize sets toast defaults" do
    toast = ToastComponent.new

    assert_equal ToastComponent::TYPE::INFO, toast.type
    assert_nil toast.title
    assert_nil toast.text
    assert_equal ToastComponent::CTA_ACTION_TYPE::CONFIRMATION, toast.cta_action_type
    assert_nil toast.cta_text
    assert_nil toast.cta_stimulus_data
  end

  test "#info sets toast type to info" do
    toast = ToastComponent.new.info("title", text: "text")

    assert_equal ToastComponent::TYPE::INFO, toast.type
    assert_equal "title", toast.title
    assert_equal "text", toast.text
  end

  test "#success sets toast type to success" do
    toast = ToastComponent.new.success("title", text: "text")

    assert_equal ToastComponent::TYPE::SUCCESS, toast.type
    assert_equal "title", toast.title
    assert_equal "text", toast.text
  end

  test "#error sets toast type to error" do
    toast = ToastComponent.new.error("title", text: "text")

    assert_equal ToastComponent::TYPE::ERROR, toast.type
    assert_equal "title", toast.title
    assert_equal "text", toast.text
  end

  test "#with_confirm_cta sets cta_action_type to confirmation" do
    stimulus_data = Views::StimulusData.new(actions: { "click" => "test#handleClick" })
    toast = ToastComponent.new.with_confirm_cta("cta_text", stimulus_data: stimulus_data)

    assert_equal ToastComponent::CTA_ACTION_TYPE::CONFIRMATION, toast.cta_action_type
    assert_equal "cta_text", toast.cta_text
    assert_equal stimulus_data, toast.cta_stimulus_data
  end

  test "#with_destructive_cta sets cta_action_type to destructive" do
    stimulus_data = Views::StimulusData.new(actions: { "click" => "test#handleClick" })
    toast = ToastComponent.new.with_destructive_cta("cta_text", stimulus_data: stimulus_data)

    assert_equal ToastComponent::CTA_ACTION_TYPE::DESTRUCTIVE, toast.cta_action_type
    assert_equal "cta_text", toast.cta_text
    assert_equal stimulus_data, toast.cta_stimulus_data
  end

  test "methods can be chained" do
    stimulus_data = Views::StimulusData.new(actions: { "click" => "test#handleClick" })
    toast = ToastComponent.new
                          .success("title", text: "text")
                          .with_confirm_cta("cta_text", stimulus_data: stimulus_data)

    assert_equal ToastComponent::TYPE::SUCCESS, toast.type
    assert_equal "title", toast.title
    assert_equal "text", toast.text
    assert_equal ToastComponent::CTA_ACTION_TYPE::CONFIRMATION, toast.cta_action_type
    assert_equal "cta_text", toast.cta_text
    assert_equal stimulus_data, toast.cta_stimulus_data
  end
end
