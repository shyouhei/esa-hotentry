## Esa hot entry list

1. `MAKEOPTS='-j 32' RUBY_CONFIGURE_OPTS='--disable-install-doc' rbenv install 2.3.0`
1. `git clone git@github.com/shyouhei/esa-hotentry`
1. `bundle install -j 32 --path=vendor/bundle`
1. `git config --local esa.space <YOUR_ESA>`
1. `git config --local esa.token <YOUR_TOKEN>`
1. `bin/rake db:migrate`
1. `bin/rails runner script/generate.rb`
1. Go take a cup of coffee, or two.
