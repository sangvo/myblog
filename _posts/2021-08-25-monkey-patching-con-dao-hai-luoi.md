---
layout: post
title: 'Monkey Patching: Từ mềm dẻo đến con dao hai lưỡi'
date: 2021-09-02 20:26 +0700
description: |
  Monkey Patching hay còn được gọi là kĩ thuật “Open Class”, mục đích cơ bản là thêm hoặc thay đổi hành vi của một class ở run-time.
  Cách áp dụng vào để mở rộng thêm các method
image:
category:
tags: rails ruby monkey-patching
published: true
sitemap: true
comments: true
toc: true
---
Gần đây mình học được 1 kỹ thuật của một anh trong công ty dùng để mở rộng một class trong ruby, giả sử ta có một method
`current_quarter` để lấy ra hiện tại đang là quý nào trong năm, thì ta sẽ viết vào module rồi `include` vào để sử dụng,
cách đó vẫn ok, nhưng nó liên quan đến ngày nên ta có thể thêm method đó vào class `Date` của ruby luôn, mỗi lần
muốn sử dụng ta chỉ cần gọi `Date.today.current_quarter`. Kỹ thuật này như nào chúng ta cùng tìm hiểu nhé :D

## Monkey Patching là gì?

**Monkey Patching** hay còn được gọi là kĩ thuật “Open Class”, mục đích cơ bản là thêm hoặc thay đổi hành vi của một class ở **run-time**.

Bạn có thường sử dụng method `blank?`, `present?`, `presence` trong rails, giả sử dụng ứng dụng của bạn **không** dùng rails khi chúng ta gọi nó sẽ như nào?

```ruby
# Inside rails
"test".blank? # => false
```

```ruby
# Outside rails
"test".blank? # => undefined method `blank?' for "test":String (NoMethodError)
```
Giờ muốn thêm `.blank?` ở ngoài ruby cho class `String` thì làm như nào? ta sẽ dụng kỹ thuật Open Class để thêm hoặc
override chúng.
```ruby
class String
  # extend non rails
   def blank?
    respond_to?(:empty?) ? !!empty? : !self
   end

   # override
  def length
     10
   end
end

p "test".blank? # => false
p "test".length # => 10
```

Ở đây chúng ta sẽ thêm `blank?` vào class `String`, còn muốn override method `length` luôn trả về 10 ta chỉ cần định
nghĩa method lại 10 thì kết quả luôn là 10. Ruby quá mềm dẻo vào lỏng lẻo nên làm chúng thành con dao 2 lưỡi, nếu sử
dụng một cách vô tội vạ thì sẽ khó kiếm soát.

## Nên tổ chức monkey patching như nào?
So easy :D
Ta chỉ cần tạo một class rồi viết.
```ruby
require 'date'
class Date
  def current_quarter
    (self.month / 3.0).ceil
  end
end

puts Date.today.current_quarter # => 3
```
Nhược điểm của cách này:
- Hiên tại nếu rails hoặc gem lib nào thêm vào method này vào thì nó vẫn sẽ bị override mãi mãi
- Nếu có ngoại lệ xảy ra thì nó sẽ raise lỗi trong `Date`
- Muốn quản lý khó khăn, nếu không muốn dùng nữa thì phải tìm rất cực nếu không có convention

Nên chúng ta sẽ học tập cách rails tổ chức:

Ví dụ rails thêm method `blank?`
```ruby
# File activesupport/lib/active_support/core_ext/object/blank.rb, line 19
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end
```
Như ví dụ đầu tiên muốn lấy ra quý hiện tại ta sẽ viết như sau
`lib/core_extensions/class_name/group.rb`

```ruby
# File lib/core_extensions/date/quarters.rb
module CoreExtensions
  module Date
    module Quarters
      def current_quarter
        (self.month / 3.0).ceil
      end
    end
  end
end

Date.include CoreExtensions::Date::Quarters

puts Date.today.current_quarter # => 3
```

Và đừng quên load nó vào file khởi tạo và reload ứng dụng, `spring stop`
```ruby
Dir["#{Rails.root}/lib/core_extensions/date/*.rb"].each { |file| require file }
```
Nếu chúng ta không muốn dùng phần nào chỉ cần comment nó là được, rất dễ dàng đúng không ^^.

## Tham khảo
- [https://www.justinweiss.com/articles/3-ways-to-monkey-patch-without-making-a-mess/](https://www.justinweiss.com/articles/3-ways-to-monkey-patch-without-making-a-mess/)
- [http://nguyenanh.github.io/2016/06/05/monkey-patching-trong-ruby](http://nguyenanh.github.io/2016/06/05/monkey-patching-trong-ruby)
