source "https://rubygems.org"

gem "jekyll", "~> 4.4"

# Theme used by this site (see _config.yml).
gem "jekyll-theme-cayman"

# GFM tables (used in get-started/index.md) need the GFM kramdown parser.
gem "kramdown-parser-gfm"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.6"
  gem "jekyll-seo-tag", "~> 2.8"
  # None of this site's Markdown pages carry YAML front matter; they rely on
  # these three plugins (all bundled by the old github-pages gem) to still be
  # treated as pages, to get a <title> derived from their leading heading, and
  # to fall back to the "default" layout.
  gem "jekyll-optional-front-matter"
  gem "jekyll-titles-from-headings"
  gem "jekyll-default-layout"
end

group :test do
  gem "html-proofer", ">=5"
end
