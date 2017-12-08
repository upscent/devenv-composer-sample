このリポジトリは、[アプリケーションサーバに引きこもるDBを自立させてDocker Composeで開発環境を作る](https://qiita.com/upscent/private/8d9ebd1f4f4cc11b12a6)のサンプルコードです。

# このサンプルコードでできること

別リポジトリのRailsアプリケーション[upscent/rails_sample_app](https://github.com/upscent/rails_sample_app)を、Rails・MySQLが同じマシンに同居する構成からそれぞれ別マシンで起動する構成に変更し、開発環境で起動することができます。

# 手順

## リポジトリのclone

devenv-composer-sampleリポジトリ(本リポジトリ)とupscent/rails_sample_appリポジトリを任意の場所にcloneします。

```sh
$ git clone git@github.com:upscent/devenv-composer-sample.git
$ git clone git@github.com:upscent/rails_sample_app.git
```

## 開発環境起動のための事前準備

### 定義ファイルの記述

upscent/rails_sample_appリポジトリのアプリケーション起動用の設定ファイル `<devenv-composer-sampleのパス>/settings.yml` を作成します。

例
```yml
rails_sample_app:
  app_root: <rails_sample_appのパス>
  app_port: <rails_sample_app起動時のホスト側のポート>
```

### Docker Composeの設定ファイルの生成とgitの設定変更

devenv-composer-sampleリポジトリにある `init.rb` スクリプトを実行し、Docker Composeの設定ファイルの生成とgitの設定変更を行います。

```sh
$ cd <devenv-composer-sampleのパス>
$ ruby init.rb
```

**Docker Composeの設定ファイル**

`<devenv-composer-samleのパス>/rails_sample_app` 以下に `docker-composer.yml` ファイルが生成されます。

**gitの設定変更**

`<rails_sample_appのパス>/.git/config` に下記のような設定が追加されます。

```
[core]
        attributesfile = .git/info/attributes_for_devenv_composer
[filter "db_host_replace"]
        smudge = cat
        clean = sed -e 's/rails_sample_app_database/localhost/g'
```

また、 `<rails_sample_appのパス>/.git/info/attributes_for_devenv_composer` というファイルが追加されます。
Qiitaの記事中では `.git/info/attributes` を直接編集していますが、こちらのサンプルコードでは既存の `.git/info/attributes` に影響が出ないよう別ファイルにしています。

## 開発環境の起動

コンテナ起動前に一度upscent/rails_sample_appリポジトリの `config/database.yml` を確認しておきましょう。
この時点ではホスト名が `localhost` のままになっているはずです。

```sh
$ cat <rails_sample_appのパス>/config/database.yml
# SQLite version 3.x
#   gem install sqlite3-ruby (not necessary on OS X Leopard)
default: &default
  adapter: mysql2
  host: localhost
  username: root
  password: root
  pool: 5
  timeout: 5000
(後略)
```

では、コンテナを起動とデータベースのmigrationを行いましょう。

```sh
$ cd <devenv-composer-sampleのパス>/rails_sample_app
$ docker-compose up -d
・
・
・
app_1  | [2017-12-08 18:05:37] INFO  WEBrick 1.3.1
app_1  | [2017-12-08 18:05:37] INFO  ruby 2.2.8 (2017-09-14) [x86_64-linux]
app_1  | [2017-12-08 18:05:37] INFO  WEBrick::HTTPServer#start: pid=10 port=3000
```

上記のようにRailsが起動したことを確認したら、別ウィンドウでDBのmigrationとサンプルデータの投入を行います。

```sh
$ cd <devenv-composer-sampleのパス>/rails_sample_app
$ dokcer-compose exec app bundle exec rake db:populate
```

これで開発環境の起動は完了です。

`http://localhost:<rails_sample_app起動時のホスト側のポート>` にアクセスできるようになっているはずです。

## ホスト名が置換されていることを確認

最後に、ホスト名が置換されていることを確認してみます。

前の手順でアプリケーションが正常に起動していれば、upscent/rails_sample_appリポジトリの `config/database.yml` のホスト名が `rails_sample_app_database` に変わっているはずです。

```sh
$ cd <rails_sample_appのパス>
# SQLite version 3.x
#   gem install sqlite3-ruby (not necessary on OS X Leopard)
default: &default
  adapter: mysql2
  host: rails_sample_app_database
  username: root
  password: root
  pool: 5
  timeout: 5000
(後略)
```

`git add .` も試してみましょう。

```sh
$ cd <rails_sample_appのパス>
$ git add .
% git status
On branch master
nothing to commit, working directory clean
```


