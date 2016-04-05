# coding: utf-8
require 'stringio'
require 'esa'

class Post < ApplicationRecord
  def self.crawl force: false
    space = Rails.application.secrets.esa_space
    token = Rails.application.secrets.esa_token
    esa   = Esa::Client.new current_team: space, access_token: token

    1.upto Float::INFINITY do |i|
      posts = esa.posts page: i, per_page: 100
      raise posts.inspect unless posts.status == 200
      posts.body['posts'].each_with_index do |j, k|
        n     = j['number']
        ctime = Time.iso8601 j['created_at']
        mtime = Time.iso8601 j['updated_at']
        obj   = find_by namespace: space, number: n
        return self if obj&.updated_at == mtime and not force # bail out no new things beyond
        obj ||= new
        obj.update_attributes(
          namespace: space,
          number: n,
          name: j['full_name'],
          url: j['url'],
          revision_number: j['revision_number'],
          comments_count: j['comments_count'],
          stargazers_count: j['stargazers_count'],
          watchers_count: j['watchers_count'],
          created_at: ctime,
          updated_at: mtime
        )
        Rails.logger.info "done #{i*100+k}/#{posts.body['total_count']})"
      end
      sleep(15 *  60.0 / 75.0)
      return self unless posts.body["next_page"]
    end
  end

  def self.to_md
    crawl
    ret = StringIO.new
    ret.printf "| 温度 | 記事 | \n"
    ret.printf "| -------- | -------- |\n"
    all.map {|i|[i, i.temperture]}.sort_by {|(i, t)|-t}.first(20).each do |(i, t)|
      ret.printf "| %5.2f | %s |\n", t, i.to_md
    end
    return ret.string
  end

  def temperture
    comments_count + Math.log(stargazers_count) + 7/6r * Math.log(watchers_count) + Math.log10(revision_number) + (created_at.to_r - Time.now.to_r) / 86400
  end

  def to_md
    sprintf '[#%d:%s](%s)', number, name, url
  end
end
