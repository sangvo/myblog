---
layout: post
title: Hướng dẫn viết chức năng unsubscribe email rails
date: 2021-04-23 17:43 +0700
description:
image:
category:
tags: rails tips
published: true
sitemap: true
comments: true
toc: true
---

## Mở đầu

Trong email marketing việc gửi mail các thông tin sự kiện hoặc tin tức cho người dùng bằng email cực kì phổ biến,
nếu để ý sẽ thấy có 1 chức năng nhỏ đó là người dùng không muốn nhận email nội
dung tương tự nữa (thường link này
sẽ được viết rất nhỏ :v).

Bắt đầu thôi!

## Generate unsubscribe token

Thông thường mấy trường hợp token chúng ta thường sẽ tạo 1 trường trong database để lưu lại và xác thực, nhưng
cách này có khá nhiều vấn đề, chúng ta sẽ phải gọi vào database mỗi lần send
mail để generate token. Trong rails cung cấp chúng ta method giúp chúng tạo ra
token và chúng ta có thể thêm dữ liệu và cũng cung cấp chúng ta method decode rađược. Method đó là `MessageVerifier`

Link đọc thêm về method này: https://api.rubyonrails.org/v6.0.3.3/classes/ActiveSupport/MessageVerifier.html

Trong controller ta sẽ xử lý như sau:
```ruby
# app/controller/events_controller.rb
def send_notice
  ...
  @unsubscribe = Rails.application.message_verifier(:unsubscribe).generate(user_id: @user.id)
  EventMailer.send_notice(@event, @user, @unsubscribe).deliver_later
end
```

Trong mailer:

```ruby
# app/mailers/event_mailer.rb
def send_notice(event, user, unsubscribe)
  @event = event
  @user = user
  @unsubscribe = unsubscribe
  mail(to: user.email, subject: "Event Info")
end
```
Nội dung email sẽ có link như sau:

```ruby
# app/views/events_mailer/send_notice.html.erb
...
<%= link_to "Unsubscribe", settings_unsubscribe_url(id: @unsubscribe) %>.
```


Thêm routes:

```ruby
# config/routes.rb
get 'settings/unsubscribe'
patch 'settings/update'
```

Thêm vào User một trường để đánh dấu user có unsubscribe hay chưa.

```ruby
rails g migration AddSubscriptionToUsers subscription:boolean
```

## Tạo controller để xử lý unsubscribe

```ruby
rails g controller Settings unsubscribe
```

Deccode để lấy user_id và xử unsubscribe
Chúng ta sử dụng hàm verify để decode token chúng ta đã generate phía trên

```ruby
# app/controllers/settings_controller.rb
def unsubscribe
  verified_params = Rails.application.message_verifier(:unsubscribe).verify(params[:id])
  @user = User.find(verified_params[:user_id])
end

def update
  @user = User.find(params[:id])
  if @user.update(user_params)
    flash[:notice] = 'Subscription Cancelled'
    redirect_to root_url
  else
    flash[:alert] = 'There was a problem'
    render :unsubscribe
  end
end

private

def user_params
  params.require(:user).permit(:subscription)
end
```

## Khi user nhấn vào liên kết sẽ vào view unsubscribe

```ruby
# app/views/settings/unsubscribe.html.erb
<h4>Unsubscribe from Mysite Emails</h4>
<p>By unsubscribing, you will no longer receive email...</p>
<%= form_for(@user, url: settings_update_path(id: @user.id)) do |f| %>
  <%= f.hidden_field(:subscription, value: false) %>
  <%= f.submit 'Unsubscribe' %>
  <%= link_to 'Cancel', root_url %>
<% end %>
```

Xong rồi rất đơn giản chúng ta có một chức năng nhỏ nhưng là một trải nghiệm tốt cho người dùng.
