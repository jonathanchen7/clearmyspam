require "test_helper"

class EmailTest < ActiveSupport::TestCase
  test "dispose_all! creates email task records" do
    user = create(:user)
    user.option.update!(archive: true)
    vendor_ids_to_archive = ["vendor1", "vendor2", "vendor3"]

    assert_difference -> { user.email_tasks.count }, 3 do
      Email.dispose_all!(user, vendor_ids: vendor_ids_to_archive)
    end

    user.option.update!(archive: false)
    vendor_ids_to_trash = ["vendor4", "vendor5", "vendor6"]
    assert_difference -> { user.email_tasks.count }, 3 do
      Email.dispose_all!(user, vendor_ids: vendor_ids_to_trash)
    end

    assert_equal 6, user.email_tasks.count
    archive_tasks = user.email_tasks.where(task_type: "archive")
    assert_equal 3, archive_tasks.count
    trash_tasks = user.email_tasks.where(task_type: "trash")
    assert_equal 3, trash_tasks.count
  end
end
