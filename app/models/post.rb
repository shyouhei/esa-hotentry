# coding: utf-8
require 'time'
require 'stringio'
require 'esa'

class Post < ApplicationRecord
  has_many :comments

  def assign_json json, space, esa
    ctime = Time.iso8601 json['created_at']
    mtime = Time.iso8601 json['updated_at']
    assign_attributes(
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
    json['comments'].each do |i|
      c = Comment.import space, i, esa, self
      self.comments << c
    end
  end

  def self.import space, json, esa
    obj  = find_or_initialize_by namespace: space, number: json['number']
    obj.assign_json json, space, esa
    return obj
  end

  def self.find_or_crawl_by esa, url
    return nil unless %r'://(?<space>.+?).esa.io/posts/(?<id>\d+)' =~ url
    i = id.to_i
    obj = find_or_initialize_by namespace: space, number: i
    if obj.new_record?
      Rails.logger.info "crawl post id:#{i}"
      res = esa.post i, include: 'comments'
      if res.status == 200
        sleep(60.0 * 15.0 / 75.0)
      else
        Rails.logger.error "failed #{res.inspect}"
        raise res.inspect
      end
      obj.assign_json res.body, space, esa
    end
    return obj
  end

  def self.crawl_page esa, space, t, page, buf
    if t
      Rails.logger.info "crawl posts until:#{t} page:#{page} per_page:100"
      query = t.strftime 'updated:<%FT%z'
      posts = esa.posts q: query, page: page, per_page: 100, include: 'comments'
    else
      Rails.logger.info "crawl posts page:#{page} per_page:100"
      posts = esa.posts page: page, per_page: 100, include: 'comments'
    end
    unless posts.status == 200
      Rails.logger.error "failed #{posts.inspect}"
      raise posts.inspect
    end
    flag = false
    ary = nil
    ActiveRecord::Base.transaction do
      buf[0] += posts.body['posts'].size
      ary = posts.body['posts'].map do |i|
        import space, i, esa
      end
      flag = ary.any?(&:changed?)
      ary.map(&:save)
      Rails.logger.info "crawl_page #{buf[0]}/#{posts.body['total_count']}"
    end
    return flag, ary.last, posts.body['next_page']
  end

  def self.crawl force: false
    space = Rails.application.secrets.esa_space
    token = Rails.application.secrets.esa_token
    esa   = Esa::Client.new current_team: space, access_token: token

    t = nil
    x = [0]
    catch :tag do
      loop do
        obj = nil
        1.upto 99 do |i|
          flag, obj, next_page = crawl_page esa, space, t, i, x
          if !next_page
            throw :tag, nil
          elsif force
            sleep(60.0 * 15.0 / 75.0)
          elsif flag
            next
          else
            throw :tag, nil
          end
        end
        t = obj.updated_at
      end
    end
    if force
      fmt = '://%s.esa.io/posts/%d'
      where(namespace: space).maximum('number').downto(0) do |i|
        unless exists?(namespace: space, number: i)
          url = fmt % [space, i]
          begin
            post = find_or_crawl_by esa, url
          rescue RuntimeError
            # 404 etc.
            sleep(60.0 * 15.0 / 75.0)
            post = new(namespace: space, number: i,
                       created_at: Time.at(0), updated_at: Time.at(0))
          ensure
            post.save
          end
        end
      end
    end
  end

  def self.to_md
    crawl # force: true
    Comment.crawl # force: true
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
