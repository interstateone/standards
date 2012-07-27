({
    mainConfigFile: './main.js',
    baseUrl: '.',
    include: ["main"],
    name: 'lib/almond.js',
    out: "./main-built.js",
    wrap: true,
    optimize: "none",
    uglify: {
        toplevel: true,
        ascii_only: true,
        beautify: true,
        max_line_length: 1000
    },
    inlineText: true,
    useStrict: false,
    pragmasOnSave: {
        excludeCoffeeScript: true,
        excludeJade: true
    },
    skipModuleInsertion: false,
    stubModules: ['text'],
    optimizeAllPluginResources: false,
    findNestedDependencies: false,
    removeCombined: false,
    preserveLicenseComments: false,

    //Sets the logging level. It is a number. If you want "silent" running,
    //set logLevel to 4. From the logger.js file:
    //TRACE: 0,
    //INFO: 1,
    //WARN: 2,
    //ERROR: 3,
    //SILENT: 4
    //Default is 0.
    logLevel: 0,
    cjsTranslate: true
})