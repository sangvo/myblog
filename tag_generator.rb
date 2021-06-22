# frozen_string_literal: true

require 'fileutils'

post_dir = '_posts/'
tag_dir = 'tag/'

filenames = Dir.glob(post_dir + '*md')
total_tags = []

filenames.each do |file_name|
  f = File.open(file_name, 'r', encoding: 'utf-8')
  crawl = false
  f.each do |line|
    if crawl
      current_tags = line.strip.split
      if current_tags[0] == 'tags:'
        total_tags << current_tags.drop(1)
        crawl = false
        break
      end
    end

    if line.strip == '---'
      if !crawl
        crawl = true
      else
        crawl = false
        break
      end
    end
  end
  f.close
end
total_tags = total_tags.flatten.uniq.compact

old_tags = Dir.glob(tag_dir + '*.md')

old_tags.each do |tag|
  FileUtils.rm(tag)
end

FileUtils.mkdir_p('tag') unless Dir.exist?('tag')

total_tags.each do |tag|
  tag_filename = tag_dir + tag + '.md'
  File.open(tag_filename, 'a') do |file|
    front_matter = <<~HEREDOC
      ---
      layout: tag
      title: "Tag: #{tag}"
      description:
      tag: #{tag}
      ---
    HEREDOC
    file.write(front_matter)
  end
end
puts("Tags generated, count: #{total_tags.size}")
