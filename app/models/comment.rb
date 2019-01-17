require 'active_support/values/time_zone'

class Comment < ApplicationRecord
  belongs_to :post

  def self.import space, json, esa, parent = nil
    ctime    = Time.iso8601 json['created_at']
    mtime    = Time.iso8601 json['updated_at']
    unless parent
      parent = Post.find_or_crawl_by(esa, json['url'])
      parent.save
    end
    obj      = find_or_initialize_by namespace: space, number: json['id']
    obj.assign_attributes(
      namespace: space,
      number: json['id'],
      post: parent,
      url: json['url'],
      created_at: ctime,
      updated_at: mtime
    )
    return obj
  end

  def self.crawl force: false
    space = Rails.application.secrets.esa_space
    token = Rails.application.secrets.esa_token
    esa   = Esa::Client.new current_team: space, access_token: token

    1.upto Float::INFINITY do |i|
      Rails.logger.info "crawl comments page:#{i} per_page:100"
      comments = esa.comments nil, page: i, per_page: 100
      unless comments.status == 200
        Rails.logger.error "failed #{comments.inspect}"
        raise posts.inspect
      end
      flag = false
      ActiveRecord::Base.transaction do
        ary = comments.body['comments'].map do |j|
          import space, j, esa
        end
        flag = ary.any?(&:changed?)
        ary.map(&:save)
        Rails.logger.info "done #{i*100}/#{comments.body['total_count']}"
      end
      if not comments.body['next_page']
        return self
      elsif force
        sleep(15 *  60.0 / 75.0)
      elsif flag
        next
      else
        return self
      end
    end
  end

  def self.updated_at_per_post
    group(:post_id).maximum(:updated_at)
  end
end
