require "test_helper"

class EmailTaskTest < ActiveSupport::TestCase
  test "validates payload for archive type" do
    email_task = build(:email_task, task_type: "archive", payload: { "some" => "data" })
    assert_not email_task.valid?
    email_task.payload = nil
    assert email_task.valid?
  end

  test "validates payload for trash type" do
    email_task = build(:email_task, task_type: "trash", payload: { "some" => "data" })
    assert_not email_task.valid?
    email_task.payload = nil
    assert email_task.valid?
  end

  test "validates payload for move type" do
    email_task = build(:email_task, task_type: "move", payload: { "other" => "data" })
    assert_not email_task.valid?
    email_task.payload = { "label_id" => "some_label_id" }
    assert email_task.valid?
  end
end
