---
layout: post
title: Github actions CI cho Ruby on rails
date: 2021-04-23 15:44 +0700
description:
image:
category: rails
tags: rails, github actions
published: true
sitemap: true
---

Các dịch vụ CI/CD ngày càng phổ biến nhứ CircleCI, TravisCI... Github cũng đã cung cấp chúng ta 1 CI cây nhà lá vườn
trên Github luôn, đó là Github Actions. Nào cùng bắt đầu setup CI cho dự án Ruby on Rails nào.

Bắt đầu thôi...!

## Mục đích

Mỗi khi developer push commit hoặc ctạo 1 pull request thì sẽ chạy check sau đây:
1. Setup môi trường của dự án
2. Run unit test (Ở đây là rspec)
3. Check Rubocop
4. Check brakeman phát hiện và cảnh báo lỗi bão mật

## Defining a Workflow

Giống như các CI khác chúng ta đều cần 1 file config. Ở thư mục root của project:
```sh
mkdir -p .github/workflows
touch .github/workflows/rails.yml
```
Đặt tên cho workflow và các sự kiện như đã nói phía trên sẽ cho 2 sự kiện là push, và pull_request
```yaml
name: Rails

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
```

## Defining a Job

Để chạy mỗi job thì chúng ta cần instance của virtual host machine. Được chỉ định bằng lệnh `runs-on`, chúng ta chạy một
số task hoặc cài đặt package thông qua lệnh `steps`.

```yaml
name: Rails

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  test:
    name: Build
    runs-on: ubuntu-latest
    steps:
    - name: Install dependencies
      run: |
        sudo apt-get -yqq install libpq-dev build-essential libcurl4-openssl-dev
        gem install bundler
        bundle install --jobs 4 --retry 3
        yarn install

```
Phía trên chúng ta định nghĩa 1 job với tên Build, và chạy trên ubuntu mới nhất(hoặc một version cụ thể). Và tiếp tục
install các package cần thiết như `libpq-dev` `build-essential` `libcurl5-openssl-dev` để có thể chạy được mysql.

## Services

Để cài đặt một containers cho một job hoặc một steps.
```yaml
jobs:
  test:
    name: Build
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:5.7
        env:
          MYSQL_ROOT_PASSWORD: root
        ports:
          - 3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
```
Ở đây chúng ta chỉ cần 1 services đó là mysql, nếu dự án cần redis hay elastic search chúng ta cũng sẽ định nghĩa nó ở
đây.

## Actions by github

Để chạy được project chúng ta cần phải checkout về trước, github cung cấp cho chúng ta actions đó là `actions/checkout`.
Còn rất nhiều actions khác ví dụ như setup ruby thì có `actions/setup-ruby`, hay để cache file chúng ta dùng
`actions/cache`...

```yaml
    steps:
    - uses: actions/checkout@v1
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 2.6.3
        bundler-cache: true

    - uses: actions/cache@v1
      with:
        path: vendor/bundle
        key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
        restore-keys: |
          ${{ runner.os }}-gems-

    - name: Set up Node
      uses: actions/setup-node@v1
      with:
        node-version: 10.13.0

    - name: Install dependencies
      run: |
        sudo apt-get -yqq install libpq-dev build-essential libcurl4-openssl-dev
        gem install bundler
        bundle install --jobs 4 --retry 3
        yarn install

    - name: Connection MySQL DB
      run: |
        sudo apt-get install -y mysql-client libmysqlclient-dev
        mysql --host 127.0.0.1 --port ${{ job.services.mysql.ports[3306] }} -uroot -proot -e "SHOW GRANTS FOR 'root'@'localhost'"
        mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --host 127.0.0.1 --port ${{ job.services.mysql.ports[3306] }} -uroot -proot mysql

    - name: Create DB
      env:
        RAILS_ENV: test
        DB_PASSWORD: root
        DB_PORT: ${{ job.services.mysql.ports[3306] }}
      run: |
        cp .env.sample .env
        sudo /etc/init.d/mysql start
        bundle exec rails db:create
        bundle exec rails db:schema:load

    - name: Run Rubocop
      run: bundle exec rubocop

    - name: Run Brakeman
      run: bundle exec brakeman

    - name: Run Rspec
      run: |
        sudo /etc/init.d/mysql start
        bundle exec rspec
````

PR: [https://github.com/sangvo/github-action-ruby](https://github.com/sangvo/github-action-ruby)
