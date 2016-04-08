require 'active_support/values/time_zone'

class Comment < ApplicationRecord
  belongs_to :post

  def self.import space, json, parent
    ctime = Time.iso8601 json['created_at']
    mtime = Time.iso8601 json['updated_at']
    obj = find_by namespace: space, number: json['id']
    return false if obj&.updated_at == mtime
    obj ||= new
    obj.update_attributes(
      namespace: space,
      number: json['id'],
      post: parent,
      url: json['url'],
      created_at: ctime,
      updated_at: mtime
    )
    return true
  end

  TZ = ActiveSupport::TimeZone['UTC']
  def self.updated_at_per_post
    a = group(:post_id).pluck(:post_id, 'MAX(updated_at)')
    a.each {|a| a[1] = TZ.parse a[1] }
    a.flatten!(1)
    return Hash[*a]
  end
end
