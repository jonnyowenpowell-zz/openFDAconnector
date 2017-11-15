## RestFUL Widgets Gulpfile

## Startup

### Build configuration object
    
    config =
        developmentBuild:    true
        version:             '0.1'
        coffeeGlob:          './coffee/**/*.?(lit)coffee'
        sassGlob:            './sass/**/*.sass'
        buildPath:           './'

### Require the necessary gulp plugins
    
    changed      = require 'gulp-changed'
    coffee       = require 'gulp-coffee'
    gulp         = require 'gulp'
    gulpif       = require 'gulp-if'
    sass         = require 'gulp-ruby-sass'
    sourcemaps   = require 'gulp-sourcemaps'
    uglify       = require 'gulp-uglify'

### Require the necessary general node modules
    
    path         = require 'path'

## Functions

### CoffeeScript functions

    compileCoffeeScript = ->
        gulp.src config.coffeeGlob
            .pipe changed config.buildPath + '/js', extension: '.js'
            .pipe gulpif config.developmentBuild, sourcemaps.init()
            .pipe coffee()
            .pipe gulpif !config.developmentBuild, uglify()
            .pipe gulpif config.developmentBuild, sourcemaps.write()
            .pipe gulp.dest config.buildPath + '/js'

### Sass functions

    compileSass = ->
        sass.clearCache()
        sass config.sassGlob,
                style: if config.developmentBuild then 'expanded' else 'compressed'
                emitCompileError: true
                sourcemap: config.developmentBuild
                quiet: true
            .pipe gulp.dest config.buildPath + '/styles'

## Tasks

### CoffeeScript tasks

    gulp.task 'coffee', compileCoffeeScript
    gulp.task 'coffee:watch', -> gulp.watch config.coffeeGlob, reloadCoffeeScript

### Sass tasks

    gulp.task 'sass', compileSass
    gulp.task 'sass:watch', -> gulp.watch config.sassGlob, reloadSass

### Build tasks

    gulp.task 'build',
        gulp.parallel 'coffee',
                      'sass'
    gulp.task 'build:watch',
        gulp.parallel 'coffee:watch',
                      'sass:watch'

### Make `build` the default task

    gulp.task 'default', gulp.parallel 'build'
