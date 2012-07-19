({
    mainConfigFile: '../public/js/main.js',
    baseUrl: '../public/js/',
    include: ["main"],
    name: 'main',
    out: "../public/js/main-built.js",
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
        // excludeJade : true
    },
    skipModuleInsertion: false,
    stubModules: ['text', 'jade'],
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
