# Ucenter

那一天，人类终于回想起了，曾经一度被UCenter所支配的恐怖。

## 安装

先在Gemfile加上:

```ruby
gem 'ucenter'
```

然后执行

    $ bundle

当然，你可以自己造一个：

    $ gem install ucenter

## 现在公开可能的情报

### 装备配置

```ruby
UCenter.configure do |config|
  config.appid   = 9
  config.charset = 'gbk' # or 'utf-8'
  config.api     = 'http://cirno.saikuang/uc_server'
  config.key     = 'bakabaka'
end

uc = UCenter.connect
```

如果要同时面对两只UCenter，怎么办？(╯°口°)╯(┴—┴

### 和UCenter谈笑风生

```ruby
uc.user_login 'username', 'password'
uc.user_synlogin uid
uc.register username,password,email
uc.user_checkname 'username'
uc.user_checkmail 'email'
uc.user_synlogout uid
uc.user_resetpwd 'username', 'password'
uc.get_user 'username'
uc.user_delete uid
...
```
## Contributing

1. Fork it ( https://github.com/[my-github-username]/ucenter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
