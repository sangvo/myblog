---
layout: post
title: Cách để tìm những orphan record trong rails
date: 2021-04-23 17:28 +0700
description:
image:
category:
tags:
published: true
sitemap: true
---

Trong quá trình phát triển chúng ta thường tạo dữ liệu "rác" ví dụ như khi xóa bảng `Class` mà chúng ta không thêm
`dependent: :destroy` hoặc chúng ta có sử dụng nhưng thiếu một vài bảng liên quan, lúc này dữ liệu các bảng con bị "mồ
côi" vì biết cha của nó là ai. Vậy nên chúng ta cần tìm chúng để xóa hoặc cập nhập lại dữ liệu

Dưới đây là một ví dụ:

Chúng ta sẽ tạo các model như sau:

```ruby
# app/models/manager.rb
class Manager < ApplicationRecord
  has_many :job_listings
end
```

```ruby
# app/models/job_listing.rb
class JobListing < ApplicationRecord
  has_many :job_applications
  belongs_to :manager
end
```

```ruby
# app/models/job_application.rb
class JobApplication < ApplicationRecord
  belongs_to :job_listing
end
```

Trước rails 6.1 chúng ta sẽ sử dụng query `left_joins` để tìm ra chúng:

```ruby
[1] pry(main)> JobListing.left_joins(:manager).where(managers: {id: nil})
JobListing Load (0.2ms)  SELECT "job_listings".* FROM "job_listings"
LEFT OUTER JOIN "managers" ON "managers"."id" = "job_listings"."manager_id"
WHERE "managers"."id" IS NULL LIMIT ?  [["LIMIT", 11]]
=> #<ActiveRecord::Relation [#<Manager id: 3, name: "Jane Doe", created_at: "2020-01-20 14:31:16", updated_at: "2020-01-20 14:31:16">]>
```

Từ rails 6.1 trở đi rails đã support ta 1 method là `missing` trong class `ActiveRecord::QueryMethods::WhereChain`. Nó
cũng sẽ trả về Relation và cũng sử dụng `left_joins` như trên.

Ví dụ:
```ruby
[1] pry(main)> JobListing.where.missing(:manager)
JobListing Load (0.1ms)  SELECT "job_listings".* FROM "job_listings"
LEFT OUTER JOIN "managers" ON "managers"."id" = "job_listings"."manager_id"
WHERE "managers"."id" IS NULL LIMIT ?  [["LIMIT", 11]]
=> #<ActiveRecord::Relation [#<Manager id: 3, name: "Jane Doe", created_at: "2020-01-20 14:31:16", updated_at: "2020-01-20 14:31:16">]>
[2] pry(main)>
```

Chúng cũng có thể pass nhiều mối quan hệ.

```ruby
[1] pry(main)> JobListing.where.missing(:manager, :job_applications)
JobListing Load (0.1ms)  SELECT "job_listings".* FROM "job_listings"
LEFT OUTER JOIN "managers" ON "managers"."id" = "job_listings"."manager_id"
LEFT OUTER JOIN "job_applications" ON "job_applications"."job_listing_id" = "job_listings"."id"
WHERE "managers"."id" IS NULL AND "job_applications"."id" IS NULL LIMIT ?  [["LIMIT", 11]]
  => #<ActiveRecord::Relation []>
[2] pry(main)>
```
Chúng sẽ trả ra những `JobListing` không có manager nào **và** cũng không có bất kì job applications

