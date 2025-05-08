# config/importmap.rb

pin "application", preload: true

# Hotwire
pin "@hotwired/turbo-rails",        to: "turbo.min.js",          preload: true
pin "@hotwired/stimulus",           to: "stimulus.min.js",       preload: true
pin "@hotwired/stimulus-loading",   to: "stimulus-loading.js",   preload: true

# All controllers in app/javascript/controllers/**/*
pin_all_from "app/javascript/controllers", under: "controllers"

# Pin npm packages by running ./bin/importmap
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js", preload: true
