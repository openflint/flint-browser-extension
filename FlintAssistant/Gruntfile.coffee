module.exports = (grunt) ->

    # Project configuration.
    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        browserify:
            content_scripts:
                files:
                    'src/js/content_scripts.js': ['lib/content_script.coffee']
                options:
                    transform: ['coffeeify']
                    browserifyOptions:
                        extensions: ['.coffee']
            background:
                files:
                    'src/js/background.js': ['lib/background.coffee']
                options:
                    transform: ['coffeeify']
                    browserifyOptions:
                        extensions: ['.coffee']

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-browserify'

    grunt.registerTask 'default', ['browserify']