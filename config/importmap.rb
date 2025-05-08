# config/importmap.rb

pin "application", preload: true

# Hotwire
pin "@hotwired/turbo-rails",        to: "turbo.min.js",          preload: true
pin "@hotwired/stimulus",           to: "stimulus.min.js",       preload: true
pin "@hotwired/stimulus-loading",   to: "stimulus-loading.js",   preload: true

# Controllers
pin "controllers/application", preload: true
pin "controllers/hello_controller", preload: true
pin "controllers/sortable_controller", preload: true
pin "controllers/flash_controller", preload: true
pin "controllers/dropdown_controller", preload: true
pin "controllers/index", preload: true

# Pin npm packages by running ./bin/importmap
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js", preload: true
