---
layout: post
title: Tích hợp CircleCI với github cho ứng dụng Ruby on Rails
date: 2021-04-27 22:05 +0700
description: Hướng dẫn tích hợp circleCI để chạy Unit Test và cá linter cho dự án Ruby on Rails
image: /assets/images/rails-circle-ci-sangv2.jpg
category:
tags: rails circle-ci ci
published: true
sitemap: true
comments: true
toc: true
---

## CI là gì?

CI là viết tắt của Continuous Integration dịch ra là "Tích hợp liên tục" là phương pháp mà các team Agile sử dụng để đảm bảo code của toàn dự án luôn build được, luôn chạy đúng (Pass toàn bộ các test case).

Ở đây có bài giải thích về CI rất đơn giản và dễ hiểu: [bài giải thích gần gũi của anh code dạo](https://toidicodedao.com/2015/08/27/giai-thich-don-gian-ve-ci-continuous-integration-tich-hop-lien-tuc/), hoặc [bài viết tiếng anh](https://www.thoughtworks.com/continuous-integration)

### CirceCI là gì?

- Nó là 1 tool giúp chúng ta thực hiện hóa quá trình tích hợp trên, CI có rất nhiều tool khác cũng nổi tiếng như (Travis CI, Jenkins...)

  Bản chất của CircleCI là sử dụng docker, trong file cấu hình của CircleCI tachỉ định các docker `image` và sử dụng các `job`, trong các `job` thì lại có các `step`, trong step thì lại có các command.

{% include image.html name="rails-circle-ci-sangv2.jpg" alt="Circle CI and Ruby on Rails" %}

## Quá trình run 1 job trên CircleCI

1. Trong quá trình phát triển developer chỉ cần push hoặc merge code vào 1 branch, Trình CircleCI sẽ tự động chạy các job tương ứng bởi event đó.
2. CircleCI sẽ pull docker image về và run lên trên môi trường cloud của nó.
3. Tiếp theo nó sẽ run các step đã được cài đặt trong docker container, thường bước đầu tiên là checkout code về :v
4. Tiếp theo chạy các step trong mình cài đặt như run rubocop, rspec, brakeman, ...
5. Sau khi tất cả các step đã chạy xong, job kết thúc. Nếu exit code của job là error thì ta sẽ nhận được mail failed và phần CircleCI sẽ báo đỏ.

 Nói tóm lại, sau khi cấu hình xong chúng ta chỉ việc dev các công việc check build, chạy test, deploy đều hoàn toàn tự động và miễn phí trên cloud của CircelCI và hoàn toàn miễn phí không yêu cầu credit card :D.

## Cài đặt CircleCI

1. Đăng nhập CircleCI, nhấn vào link: https://circleci.com/vcs-authorize/ chọn
**Login with github** Chúng ta sẽ thấy tất cả các repo hiện có trên tài khoản của mình.
2. Chọn project cần setup CircleCI

![Giao diện project CircleCI](https://user-images.githubusercontent.com/19734293/90332520-c001bc00-dfe7-11ea-9d51-2dbdef2ce66a.png)

Nhấn vào Set Up project cho dự án muốn sử dụng CircelCI.

Nếu trong project ta đã có file confg circleci `.circleci/config` thì chỉ cần nhấn start building là bắt đầu, nếu chưa có chúng ta bắt đầu tạo thôi ^^.

3. Cấu hình file CircleCI

Chúng ta bắt đầu tạo file config trong thư mục root dự án.

```sh
mkdir .circleci
touch .circleci/config.yml
```

Đây là file config example cho dự án RoR

{% raw %}
```yaml
version: 2.1

executors:
  default:
    docker:
      - image: circleci/ruby:2.6.3-node
        environment:
          BUNDLE_JOBS: 3
          BUNDLE_PATH: vendor/bundle
          BUNDLE_RETRY: 3
          BUNDLER_VERSION: 2.0.1
          RAILS_ENV: test
      - image: circleci/mysql:5.7
        command: [--default-authentication-plugin=mysql_native_password]
        environment:
          MYSQL_ALLOW_EMPTY_PASSWORD: true

commands:
  configure_bundler:
    description: Configure bundler
    steps:
      - run:
          name: Configure bundler
          command: |
            echo 'export BUNDLER_VERSION=$(cat Gemfile.lock | tail -1 | tr -d " ")' >> $BASH_ENV
            source $BASH_ENV
            gem install bundler

jobs:
  build:
    executor: default
    steps:
      - checkout
      - restore_cache:
          keys:
            - rails_demo_bundler-{{ .Branch }}-{{ checksum "Gemfile.lock" }}
            - rails_demo_bundler-
      - configure_bundler
      - run:
          name: Install bundle
          command: bundle install
      - run:
          name: Wait for DB
          command: dockerize -wait tcp://127.0.0.1:3306 -timeout 1m
      - run:
          name: Setup DB
          command: bundle exec rails db:setup --trace
      - run:
          name: Run Rubocop
          command: bundle exec rubocop
      - run:
          name: Run Rspec
          command: bundle exec rspec --format progress
      - save_cache:
          key: rails_demo_bundler-{{ .Branch }}-{{ checksum "Gemfile.lock" }}
          paths:
            - vendor/bundle

workflows:
  version: 2
  integration:
    jobs:
      - build
```
{% endraw %}

 Dòng đầu tiên đó là version của CircleCI hiện tại đang là version `2.1`

- Phần đầu tiên là executors chúng ta có thể định nghĩa environtment và các bước sẽ được chạy. Ở đây mình setup môi trường ruby 2.6.3 và mysql 5.7. và các biến môi trường của chúng. Viết ra thành executors chúng ta có thể tái sử dụng chúng.

- Tiếp theo là phần `commands` định nghĩa các step của một job và cũng có thể tái sử dụng chúng. Ở đây đã tách phần bundler thành 1 command sau chúng ta có thể tái sử dụng chúng ở phía dưới.

Lưu ý: Phần executors và commands này yêu cầu version circelCI là 2.1

- Phần tiếp theo là phần jobs, chúng sẽ chứa các step mà chúng ta cần chạy ví dụ để chạy rails chúng ta cần install bundler thì mình đã tách ra phía trên nên dưới này chỉ cần gọi lại, tiếp theo `bundle install` ...

- Phần cuối cùng là `workfolows` ở đây chúng ta sẽ định nghĩa chạy jobs nào ở phía trên sẽ chạy chỉ job build mà thôi, ở đây có rất nhiều options rất hay như `schedule`, `fileters`, `branches` config chỉ chạy branch nào hoặc hoặc không chạy branch nào, hẹn giờ chạy... Muốn tìm hiểu thêm nhiều config [ở đây](https://circleci.com/docs/2.0/configuration-reference/#workflows)


Repo setup: [https://github.com/sangvo/docker-circleci-example](https://github.com/sangvo/docker-circleci-example)

---
