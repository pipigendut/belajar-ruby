=begin
Ini adalah rails template

cara menggunakannya :
rails new blog -m ~/advanced-rails-project-template.rb
=end

# frozen_string_literal: true

require "json"

def confirm(question)
  response = ask("#{question} [Y/n]")
  response == "" || response.upcase == "Y"
end

USE_ESLINT_STANDARD = confirm("Use ESLint standard style ?")
USE_STANDARDRB = confirm("Use Ruby standard style (https://github.com/testdouble/standard) ?")
USE_LINT_STAGED = confirm("Install lint-staged (https://github.com/okonet/lint-staged) ?")
USE_DEVISE = confirm("Install devise for authentication ?")
USE_CAPISTRANO = confirm("Install capistrano to automate deployment ?")
USE_HOTWIRE = confirm("Install hotwire ?")
# webpacker 6 use webpack 5, which have better build performance
# https://medium.com/frontend-digest/whats-new-in-webpack-5-ef619bb74fae
# the one that makes it better is uses dart-sass instead of node-sass
# https://github.com/rails/webpacker/#sass
USE_WEBPACKER6_BETA = confirm("Use webpacker 6.0.0.beta.5 ?")
BINSTUBS = []

def package_json
  @package_json ||= begin
    package_json = File.exist?("package.json") ? JSON.parse(File.read("package.json")) : {}
    package_json["scripts"] ||= {}
    package_json
  end
end

def use_webpacker6_beta?
  @use_webpacker6_beta ||= begin
    webpacker_checker_regex = /gem (['"])webpacker\1.+/
    return false unless USE_WEBPACKER6_BETA && File.read("Gemfile")[webpacker_checker_regex]

    gsub_file "Gemfile", webpacker_checker_regex, %(gem "webpacker", "~> 6.0.0.beta.5")
    # add sass and sass-loader
    run "yarn add sass sass-loader"

    true
  end
end

gem "factory_bot_rails", group: [:development, :test]
gem "rspec-rails", "~> 4.0.1", group: [:development, :test]
gem "guard-rspec", require: false, group: :development
gem "guard-livereload", "~> 2.5.2", require: false, group: :development
gem "rack-livereload", group: :development
gem "spring-commands-parallel-tests", require: false, group: :development
gem "spring-commands-rspec", require: false, group: :development
gem "dotenv-rails"
use_webpacker6_beta?

def edit_file(path)
  File.write(path, yield(File.read(path)))
end

def log_header(text)
  puts
  puts "### #{text}"
end

def install_eslint
  return unless USE_ESLINT_STANDARD

  log_header "Installing ESLint"

  package_json["scripts"]["lint:js"] = "./node_modules/.bin/eslint --cache app/javascript"
  eslint_packages = %w[
    eslint
    eslint-config-standard
    eslint-plugin-import
    eslint-plugin-node
    eslint-plugin-promise
  ]
  package_json["devDependencies"] ||= {}
  eslint_packages.each do |package|
    package_json["devDependencies"][package] = "latest"
  end

  run "yarn add -D #{eslint_packages.join(" ")}"

  file ".eslintrc.js", <<~JS
    module.exports = {
      env: {	
        browser: true,	
        es2021: true	
      },	
      extends: [	
        'standard'	
      ],	
      parserOptions: {	
        ecmaVersion: 12,	
        sourceType: 'module'	
      },	
      rules: {	
      }	
    }
  JS
end

def install_devise
  return unless USE_DEVISE

  log_header "Installing Devise"
  gem "devise"
  generate("devise:install")
  generate("devise", "user")
  run "bundle exec rails db:migrate"
end

def install_lint_staged
  return unless USE_LINT_STAGED

  log_header "Installing lint-staged"
  package_json["scripts"]["lint-staged"] = {
    "*.js": "eslint --cache --fix",
    "{Guardfile,Gemfile,*.rb}": "bin/standardrb --fix"
  }
  run "npx mrm lint-staged"
end

def install_standardrb
  return unless USE_STANDARDRB

  log_header "Installing standardrb"

  package_json["scripts"]["lint:rb"] = "bin/standardrb"
  BINSTUBS << "standardrb"

  gem "standard", group: :development
  gem "spring-commands-standard", require: false, group: :development

  file "standard.yml", <<~YAML
    parallel: true          # default: false
    format: progress        # default: Standard::Formatter

    ignore:
      - "**/db/schema.rb"
      - "**/db/*_schema.rb"
      - "**/bin/*"
  YAML
end

def install_rspec
  log_header "Installing rspec"

  package_json["scripts"].merge!(
    "test" => "bin/rspec",
    "test:all" => "yarn run test -- --tag '~focus' --tag 'focus'",
    "test:failures" => "yarn run test:all --only-failures"
  )
  BINSTUBS << "rspec"

  # fix rspec:install stuck by stop spring
  # https://github.com/rspec/rspec-rails/issues/1860#issuecomment-346687123
  run "spring stop"
  generate("rspec:install")

  # delete minitest directory
  run "rm -rf test/"

  inside "spec" do
    # make spec/support directory loaded
    edit_file("./rails_helper.rb") do |content|
      content.sub!(%r{^# (?=Dir\[Rails.root.join\()}, "")
    end

    # add some rspec configuration by removing specific comment
    edit_file("./spec_helper.rb") do |content|
      # delete block comment
      content["=begin"] = ""
      content["=end"] = ""
      # commenting the unnecessary config
      content
        .sub!(%r{(?=config.profile_examples = 10)}, "# ")
        .sub!(%r{(?=config.order = :random)}, "# ")
        .sub!(%r{(?=Kernel.srand config.seed)}, "# ")
    end
  end

  # generate rspec supports
  file "spec/support/factory_bot.rb", <<~RUBY
    RSpec.configure do |config|
      config.before { FactoryBot.rewind_sequences }
    end
  RUBY
end

def install_capistrano
  return unless USE_CAPISTRANO

  log_header "Installing Capistrano"

  gem "capistrano", "~> 3.15", require: false
  gem "capistrano-rbenv", "~> 2.2", require: false
  gem "capistrano-rails", "~> 1.6", require: false

  run "bundle exec cap install"

  edit_file("./Capfile") do |file|
    file
      .sub!(%r{# (?=require "capistrano/rbenv")}, "")
      .sub!(%r{# (?=require "capistrano/bundler")}, "")
      .sub!(%r{# (?=require "capistrano/rails/assets")}, "")
      .sub!(%r{# (?=require "capistrano/rails/migrations")}, "")
  end

  edit_file("./config/deploy.rb") do |file|
    file
      .sub!(%r{# append :linked_dirs.+}, <<~RUBY)
        append :linked_dirs,
          "log",
          "tmp/pids",
          "tmp/cache",
          "tmp/sockets",
          "node_modules",
          "bundle"
      RUBY
      .sub!(%r{# append :linked_files.+}, <<~RUBY)
        append :linked_files, ".env.production.local"
      RUBY
  end

  append_file "./config/deploy.rb", <<~RUBY
    Rake::Task["deploy:assets:backup_manifest"].clear_actions
  RUBY
end

def install_hotwire
  return unless USE_HOTWIRE

  log_header "Installing Capistrano"

  gsub_file "./config/application.rb", %r{# (?=require "sprockets/railtie")}, ""
  gem "hotwire-rails"
  run "bundle exec rails hotwire:install"
end

after_bundle do
  install_rspec
  install_eslint
  install_lint_staged
  install_standardrb
  install_devise
  install_hotwire
  File.write("package.json", JSON.pretty_generate(package_json))

  if use_webpacker6_beta?
    run "bundle exec rails webpacker:install"
    run "mv app/javascript app/packs"
    run "mv app/packs/packs app/packs/entrypoints"

    edit_file("config/webpacker.yml") do |content|
      content.sub!(%r{(?<=source_path: )app/javascript}, "app/packs")
      content.sub!(%r{(?<=source_entry_path: )packs}, "entrypoints")
    end
  end

  run "bundle exec spring binstub #{BINSTUBS.join(" ")}"

  # generate home page
  generate(:controller, "home", "index", "--skip-routes")
  route %(root to: "home#index")

  git add: "."
  git commit: %( -m "initial commit" )
end
