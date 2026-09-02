# HOW TO BUILD LOCALLY #

This directory already contains a `Gemfile` pinning the Jekyll toolchain used
to build the site, so there is no need to create one from scratch.

* Install Ruby (>= 3.1) and Bundler (**gem install bundler**)
* From this directory, install the gems: **bundle install**
    * If some gem fails to install, use this: **gem install gem_name -v 'version' --source 'https://rubygems.org/'**
* Execute Jekyll: **bundle exec jekyll serve**
    * If the port is in use, add **--port port_number**

## WINDOWS ##

Open a terminal (on Windows, every command should be executed from the **git bash**) inside this directory (**not** the repository root), then follow the steps above. Download Ruby from [here](https://rubyinstaller.org/downloads/) if it is not already installed.

### PROXY ###

The following should work for every command:

* export http_proxy=http://user:password@host:port
* export HTTP_PROXY=$http_proxy
* export https_proxy=http://user:password@host:port
* export HTTPS_PROXY=$https_proxy

Besides, the **gem install** command has another parameter: --http-proxy http://user:password@host:port

## REFERENCE ##

This [guide](https://help.github.jp/enterprise/2.11/user/articles/setting-up-your-github-pages-site-locally-with-jekyll/)
[Mac guide](https://jekyllrb.com/docs/installation/macos/)
