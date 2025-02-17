# == Schema Information
#
# Table name: filters
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#  vendor_id  :string
#
class Filter < ApplicationRecord
end
