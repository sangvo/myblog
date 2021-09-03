---
layout: post
title: 'Presenter pattern rails: Quản lý view tuyệt vời'
date: 2021-09-03 20:42 +0700
description: 
image: 
category: 
tags: 
published: true
sitemap: false
comments: true
toc: true
series: "Rails design pattern"
---
Nghỉ lễ mà dich phức tạp quá không làm gì được, chán ghê :( Viết blog tiếp vậy :D

Trong rails mặc khi ta generate controller thì rails sẽ tạo luôn cho chúng ta một file helper, chúng ta có thể viết các xử lý logic ở đây, nhưng các method ở đây sẽ được gọi ở bất kì đâu trong view, đều này thật không hay chúng ta cần quản lý chúng theo các view đễ sau dễ maintain.

Bắt đầu thôi!...

## Presenter pattern là gì?
Đơn giản nó cũng chỉ là Plain Old Ruby Objects (PORO) chúng ta sẽ viết các method support và gọi chúng ở view.

Cấu trúc folder:
```
├── app
│ ├── assets
│ ├── channels
│ ├── controllers
│ ├── decorators
│ ├── forms 
│ ├── helpers
│ ├── jobs
│ ├── mailers
│ ├── models
│ ├── presenters 👈 store presenter objects classes here 
│ ├── queries
│ ├── services
│ └── views
```

## Cách sử dụng
Ví dụ đơn giản, khi user login tùy theo role ta sẽ có message welcome khác nhau
```ruby
# app/views/users/index.html.slim
span.welcome_message
  - if user.member?
    = t('users.welcome.member')
  - else
    = t('users.welcome.admin')
```
If/else ở view thật sử là một lựa chọn tồi ta sẽ viết nó vào presenter
```ruby
# app/presenters/user_presenter.rb
class UserPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def welcome_message
    return I18n.t('users.welcome.member') if user.member?

    I18n.t('users.welcome.admin')
  end

  # more method, options for select...
end
```
Giờ ở view ta sẽ viết lại như sau
```ruby
span.welcome__message
  = @user_presenter.welcome_message
```
Controller:
```ruby
class UserController
  def index
    @user_presenter = UserPresenter.new(current_user)
  end
end
```
Giờ tất cả các data ở màn view này ta sẽ xử lý trong class `UserPresenter` ví dụ như: các câu điều kiện hiển thị, các options của các dropdown...

> Lưu ý, presenter chỉ xử lý data hiển thị phần view, khi muốn format data ở backend(api, service, controller...) thì nên sử dụng `decorate pattern`

## Tổng kết
Thật sự pattern này rất đơn giản đúng không ^^, nhưng nó giúp chúng ta quản lý data ở view thật sử tuyệt vời.