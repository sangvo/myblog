---
layout: post
title: 'Query Object trong Rails: search thật đơn giản!'
description: |
  Áp dụng design pattern Query Object để search/filter nâng cao trong ruby on rails, giúp code clear và dễ maintain
  hơn.
category:
image:
tags: rails rails-design-patterns
toc: true
sitemap: true
comments: true
published: true
date: 2021-06-15 10:08 +0700
---
## Mở đầu
Chuyện về search/filter trong các ứng dụng cực kì phổ biến đặc biết trong các trang thương mại điện tử hay ở admin
panel... đối với những form chỉ đơn giản một vài text box thì viết sao cũng được, nhưng khi form search có cả chục field
cần filter thì lúc này cần áp dụng *design pattern* để người sau maintainer không phải bối rối :penguin:

Pattern thường sử dụng ở Ruby on rails là: **Query Object**

### Query object là gì?
**Query Object** đơn giản là PORO Object giúp chúng ta thực hiện các truy vấn lớn hoặc phức tạp thay vì ở model hay
controller.

### Tại sao cần chúng?
- Giúp chúng ta dễ maintainer, debug
- Tránh đặt logic nặng dễ fat controller hoặc fat model.
- Dễ viết Unit Test hơn

## Thực hành
Giả sử chúng ta sẽ làm một form search sản phẩm:
- Search theo tên sản phẩm, giá cả, danh mục sản phẩm.
- Sắp xếp chúng theo giá cả. ngày tạo.

Ta có controller Product như sau:
```ruby
class ProductsController < ApplicationController
  def index
    price_sort_direction = params[:price_sort_direction].to_sym || :desc
    @products = Product.order(price: price_sort_direction).page(params[:page]).per(params[:per_page])
  end
end
```
Nhưng chúng ta không phải lúc nào cũng sắp xếp theo giá tiền, chúng ta cần sắp xếp theo ngày tạo nữa.
Viết lại 1 tí:

```ruby
def index
  sort_direction = params[:sort_direction].to_sym || :desc
  sort_field = params[:sort_field].to_sym || :price
  @products = Product.order(sort_field => sort_direction).page(params[:page]).per(params[:per_page])
end
```

Giờ chúng ta bắt đầu search:
```ruby
  @products = Product.all

  search = params[:q]
  @products = @products.where("title LIKE ?", "%#{search}%") if search

  from_price = params[:price_from]
  @products = @products.where('price >= ?', price_from) if price_from

  to_price = params[:price_to]
  @products = @products.where('price <= ?', to_price) if price_to

  category_id = params[:category_id]
  @products = @products.where(category_id: category_id) if category_id

  sort_direction = params[:sort_direction].to_sym || :desc
  sort_field = params[:sort_field].to_sym || :price
  @products = @products.order(sort_field => sort_direction).page(params[:page]).per(params[:per_page])
```

Nhìn đống code trên thật là lộn xộn, giả sử sau này thêm khoảng n field nữa thì sao, controller chúng ta sẽ rất dài, cho
dù chúng ta tách hàm xử lý ở dưới hay model thì nó vẫn khá phức tạp.

## Refactoring với Query Object

```ruby
class ProductsController < ApplicationController
  def index
    @products = SearchProducts.new(products: Product.all).call(search_params)
    render json: {products: @products}
  end

  def search_params
    params.permit(:q, :price_from, :price_to, :category_id,
                  :sort_direction, :sort_field, :page, :per_page)
  end
end
```
Giờ chúng ta sẽ tạo folder `queries`
```sh
mkdir app/queries
```
Tạo file `search_products.rb`
```sh
touch app/queries/search_products.rb
```
```ruby
class SearchProducts
  attr_accessor :products

  def initialize(products:)
    @products = products
  end

  def call(search_params)
    scoped = search(products, search_params[:q])
    scoped = filter_by_price(scoped, search_params[:price_from], search_params[:price_to])
    scoped = filter_by_category(scoped, search_params[:category_id])
    scoped = sort(scoped, search_params[:sort_field], search_params[:sort_direction])
    scoped = paginate(scoped, search_params[:page], search_params[:per_page])
    scoped
  end

  private

  def search scoped, query = nil
    query ? scoped.where("title LIKE ?", "%#{query}%") : scoped
  end

  def filter_by_price scoped, price_from = nil, price_to = nil
    scoped = price_from ? scoped.where("price >= ?", price_from) : scoped
    price_to ? scoped.where("price <= ?", price_to) : scoped
  end

  def filter_by_category scoped, category_id
    category_id ? scoped.where(category_id: category_id) : scoped
  end

  def sort scoped, sort_field, sort_direction, default = {order: :price, sort: :desc}
    allowed_fields = %w(price created_at)
    order_by_field = allowed_fields.include?(sort_field) ? sort_field : default[:order]
    order_direction = %w(asc desc).include?(sort_direction) ? sort_direction : default[:sort]

    scoped.order({order_by_field => order_direction})
  end

  def paginate scoped, page, per_page
    scoped.page(page).per(per_page) # kaminari
  end
end
```
Thêm routes và test thôi :D
```
http://localhost:3000/products?q=&price_from=10000
```
Kết quả:
```json
{
  products: [
    {
      id: 3,
      title: "T-Shirt 2",
      price: "40000.0",
      category_id: 1,
      created_at: "2021-06-14T15:42:14.169Z",
      updated_at: "2021-06-14T15:42:14.169Z"
    },
    {
      id: 2,
      title: "T-Shirt 2",
      price: "20000.0",
      category_id: 1,
      created_at: "2021-06-14T15:42:04.500Z",
      updated_at: "2021-06-14T15:42:04.500Z"
    },
    {
      id: 1,
      title: "T-Shirt",
      price: "10000.0",
      category_id: 1,
      created_at: "2021-06-14T15:28:00.136Z",
      updated_at: "2021-06-14T15:28:00.136Z"
    }
  ]
}
```

## Viết Unit Test
Example:
```ruby
RSpec.describe SearchProducts do
  let!(:product_1) { create :product, price: 10 }
  let!(:product_2) { create :product, price: 20 }
  let!(:product_3) { create :product, price: 30 }
  let(:products) { Product.all }

  subject { described_class.new(products: products).call(search_params) }

  context "with empty params" do
    let(:search_params) { {} }

    it "sorts" do
      expect(subject.size).to eq 3
      expect(subject.ids).to eq [product_3.id, product_2.id, product_1.id]
    end

    it "paginates" do expect(subject.total_pages).to eq 1
      expect(subject.total_count).to eq 3
      expect(subject.current_page).to eq 1
    end
  end

  context "with search price" do
    let(:search_params) { {price_from: 20} }
    it do
      expect(subject.size).to eq 2
    end
  end

  # TODO: category, tile, something ...
end
```

## Tổng kết
Như vậy mình đã hướng dẫn sử dụng **Query Object** refactor form search xong rồi ^^, hi vọng giúp ích cho các bạn khi gặp
các form **search nâng cao**.

- Link source code example: [https://github.com/sangvo/rails_design_pattern/](
https://github.com/sangvo/rails_design_pattern/){:target="_blank"}

- References:
[https://mkdev.me/en/posts/how-to-use-query-objects-to-refactor-rails-sql-queries](https://mkdev.me/en/posts/how-to-use-query-objects-to-refactor-rails-sql-queries){:target="_blank"}
