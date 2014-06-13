exports.config =
  # See docs at brunch.io, mostly went by examples.
  conventions:
    assets:  /^app[\/\\]+assets[\/\\]+/
    ignored: /^(bower_components[\/\\]+bootstrap-less(-themes)?|app[\/\\]+styles[\/\\]+overrides|(.*?[\/\\]+)?[_]\w*)/
  modules:
    definition: false
    wrapper: false
  paths:
    public: 'public'
  files:
    javascripts:
      joinTo:
        'js/app.js': /^app/
        'js/vendor.js': /^(app|bower_components|vendor)/
    stylesheets:
      joinTo:
        'css/app.css': /^(app|vendor|bower_components)/
    templates:
      joinTo:
        'js/dontUseMe' : /^app/ # dirty hack for Jade compilation via plugin
  plugins:
    jade:
      pretty: yes # Adds pretty-indentation whitespaces to output (false by default)
    jade_angular:
      modules_folder: 'partials'
      locals: {}
  minify: true # Enable or disable minifying of result js / css files.
