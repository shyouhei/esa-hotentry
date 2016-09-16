# coding: utf-8
require 'stringio'
require 'esa'

class Post < ApplicationRecord
  has_many :comments

  def self.import space, json
    ctime = Time.iso8601 json['created_at']
    mtime = Time.iso8601 json['updated_at']
    obj   = find_by namespace: space, number: json['number']
    return false, obj if obj&.updated_at == mtime
    obj ||= new
    obj.update_attributes(
      namespace: space,
      number: json['number'],
      name: json['full_name'],
      url: json['url'],
      revision_number: json['revision_number'],
      comments_count: json['comments_count'],
      stargazers_count: json['stargazers_count'],
      watchers_count: json['watchers_count'],
      created_at: ctime,
      updated_at: mtime
    )
    return true, obj
  end

  def self.crawl force: false
    space = Rails.application.secrets.esa_space
    token = Rails.application.secrets.esa_token
    esa   = Esa::Client.new current_team: space, access_token: token

    1.upto Float::INFINITY do |i|
      posts = esa.posts page: i, per_page: 100, include: 'comments'
      raise posts.inspect unless posts.status == 200
      flag = false
      posts.body['posts'].each do |j|
        f1, obj = import space, j
        flag ||= f1
        j['comments'].each do |k|
          f2 = Comment.import space, k, obj
          flag ||= f2
        end
      end
      Rails.logger.info "done #{i*100}/#{posts.body['total_count']}"
      return self if !flag && !force # bail out no new things beyond
      sleep(15 *  60.0 / 75.0)
      return self unless posts.body["next_page"]
    end
  end

  def self.to_md
    crawl
    @@id2updated_at = Comment.updated_at_per_post
    ret = StringIO.new
    ret.printf "| 温度 | 記事 | \n"
    ret.printf "| -------- | -------- |\n"
    all.map {|i|[i, i.temperture]}.sort_by {|(i, t)|-t}.each do |(i, t)|
      break if t < 1
      ret.printf "| %5.2f | %s |\n", t, i.to_md
    end
    return ret.string
  end

  def last_action_at
    [ @@id2updated_at[id], updated_at ].compact.max
  end

  def temperture
    (last_action_at.to_r - Time.now.to_r) / 86400 +
      Math.log(comments_count + 1) + Math.log(comments_count + stargazers_count + 7/6r * watchers_count + 1/7r * revision_number)
  end

  def to_md
    sprintf '[#%d:%s](%s)', number, name, url
  end
end
