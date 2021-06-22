---
layout: post
title: Hướng dẫn xây dựng template để start project rails siêu nhanh
date: 2021-05-17 19:35 +0700
description:
image: /assets/images/rails-generator-template-ok.png
category:
tags: rails dry
published: true
sitemap: true
comments: true
toc: true
---

Heyo!! Hôm nay mình sẽ hướng dẫn các tạo 1 generator để dựng mới 1 project bằng rails cực nhanh cực ngầu. Từ lúc newbie
việc tạo một project mới rails đơn giản chỉ cần `rails new super_project` là rails sẽ tạo 1 project, chỉ cần `rails s`
là có thể chạy ngon ơ. Nhưng dần dần khi bắt đầu quen với nó rồi, bắt đầu tiếp xúc với các tool linter như `rubocop`, hoặc chạy trên `docker`,
hay các config cơ bản như `mailer`, `database`... thì nó mất khá nhiều thời gian để start 1 project. Bắt đầu thôi...

## Ruby on Rails - Application Template là gì?

> Application templates are simple Ruby files containing DSL for adding gems/initializers etc. to your freshly created Rails project or an existing Rails project.

Nôm na nó là 1 file cho phép chúng ta thêm mới gem hoặc initializers lúc tạo mới 1 project hoặc chỉnh sửa các project đã
tồn tại vẫn ok.

## Cách sử dụng Template

Bình thường chúng ta sẽ tạo `rails new project` trong đó chứa rất nhiều options cho chúng ta sử dụng như -d để tạo loại
DB gì như MySQL, PostgreSQL, hoặc các options skip unitest...

{% include image.html name="rails-new-help-sangv2.png" alt="Ruby on rails new help" caption="Ruby on rails new help" %}

Trong đó có 1 option là `--template`

```ruby
rails new project --template /path/to/template.rb
rails new project --template https://example.com/template.rb
```
Chúng ta tạo 1 file `template.rb` ở trên máy hoặc trên host cá nhân hay github điều được.(template.rb hay gì bạn thích
là được ^^)

### Trong file template chúng ta có thể làm gì?
* Ghi đè các file đã được generator bởi rails :smile:
* Add bất cứ gem gì bạn muốn theo các step của gem luôn
* Tạo thêm file, copy chỉnh sửa file (wow)
* Tạo bảng trong DB cũng ok luôn
* Chạy lên `git`
* Define sẵn các hàm để `say`, `yes?`

Và quan trọng nhất chúng ta có thể run bất cứ `command` luôn (phe)

Đủ rồi tạo luôn cho nóng:

```sh
vim workspace/rails_templates/template.rb
```

Thử với đoạn generator như sau:

```ruby
 # frozen_string_literal: true

# Remove comment in gem file
def remove_comment_of_gem
  gsub_file('Gemfile', /^\s*#.*$\n/, '')
end

remove_comment_of_gem

say 'Applying rubocop ...'
gem_group :development, :test do
  gem 'rubocop'
end

after_bundle do
  run 'bundle exec rubocop --auto-correct'
end
```

Giải thích chút:
- Đầu tiên nó chúng ta sẽ remove hết các comment trong Gemfile cho nó sạch sẽ
- Tiếp theo chúng ta sẽ add gem rubocop vào group `development` và `test`
- Sau đó chúng ta sẽ sử dụng rubocop để fix những lỗi linter trong project chúng ta.

Chạy thử xem có ra như mong đợi không nào!!!

```sh
rails new project_name --template=/path/to/local/template.rb
```
Thư giản ngẫm nghĩ chuyện đời một xíu...

Kiểm tra kết quả thôi.

{% include image.html name="rails-generator-template-ok.png" alt="Ruby on rails gemfile clear" caption="Ruby on rails Gemfile" %}

## Tổng kết
Ở bài viết mình giới thiệu cơ bản DSL template, bạn có thể định nghĩa cho riêng mình một cái với style của bạn, thà một
lần đau đầu còn hơn vạn lần phải copy qua, copy lại :pray:

Đây là templete mình mix lại: [rails templates](https://github.com/sangvo/rails_templates)
