<?php
/**
 * This configuration file determines which namespaces are used by any
 * features, extensions or plugins you add to your theme. Additionally,
 * you can provide an alternative fully-qualified class name for your
 * theme's main file, which by default can be found at app/Theme.php.
 * 
 * Modify these configurations only if you intend to use alternative
 * namespaces.
 */

return [
    'theme_class'          => 'App\\Theme',
    'features_namespace'   => 'App\\Features',
    'extensions_namespace' => 'App\\Extensions',
    'plugins_namespace'    => 'App\\Plugins',

    /**
     * The following arrays store information needed to bootstrap
     * your theme's features, extensions and plugins. 
     * 
     * They are updated automatically when any of the three package 
     * types are installed. You can modify their values if needed.
     */

    // Installed features
    'features' => [
        'App\\Features\\ThemeStyles\\FeatureDefinition' => 'FeatureDefinition.php',
    ],

    // Installed extensions
    'extensions' => [
        'App\\Extensions\\MerosDynamicPage' => 'MerosDynamicPage.php',
    ],

    // Installed plugins
    'plugins' => [
        'App\\Plugins\\MerosDynamicHeader' => [
            'config' => 'MerosDynamicHeader.php',
            'src' => 'plugins/meros-dynamic-header/meros-dynamic-header.php',
        ],
        'App\\Plugins\\MerosCarousel' => [
            'config' => 'MerosCarousel.php',
            'src' => 'plugins/meros-carousel/meros-carousel.php',
        ],
        'App\\Plugins\\MerosTextAnimations' => [
            'config' => 'MerosTextAnimations.php',
            'src' => 'plugins/meros-text-animations/meros-text-animations.php',
        ],
    ]
];
