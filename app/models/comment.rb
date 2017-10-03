require 'active_support/values/time_zone'

class Comment < ApplicationRecord
  belongs_to :post

  def self.import space, json, parent = nil
    ctime = Time.iso8601 json['created_at']
    mtime = Time.iso8601 json['updated_at']
    obj = find_by namespace: space, number: json['id']
    return false if obj&.updated_at == mtime
    parent ||= find_post_using_url(json['url'])
    raise "unable to find post: #{json['url']}" unless parent
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

  def self.find_post_using_url url
    return nil unless %r'esa.io/posts/(?<id>\d+)' =~ url
    return Post.find_by(number: id.to_i)
  end

  def self.crawl force: false
    space = Rails.application.secrets.esa_space
    token = Rails.application.secrets.esa_token
    esa   = Esa::Client.new current_team: space, access_token: token

    1.upto Float::INFINITY do |i|
      comments = esa.comments nil, page: i, per_page: 100
      raise comments.inspect unless comments.status == 200
      flag = false
      comments.body['comments'].each do |j|
        f1, obj = import space, j
        flag ||= f1
      end
      Rails.logger.info "done #{i*100}/#{comments.body['total_count']}"
      return self if !flag && !force # bail out no new things beyond
      sleep(15 *  60.0 / 75.0)
      return self unless comments.body["next_page"]
    end
  end

  def self.updated_at_per_post
    group(:post_id).maximum(:updated_at)
  end
end
