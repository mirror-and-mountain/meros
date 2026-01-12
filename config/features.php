<?php
/**
 * This configuration file determines which namespaces are used by any
 * features or extensions you add to your theme. Additionally,
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

    /**
     * The following arrays store information needed to bootstrap
     * your theme's features and extensions. 
     * 
     * They are updated automatically when either of the package 
     * types are installed. You can modify their values if needed.
     */

    // Installed features
    'features' => [],

    // Installed extensions
    'extensions' => []
];
