<?php

return [
    /**
     * The 'theme_class' key determines the fully-qualified class name of your
     * theme's main file. By default, it is set to 'App\\Theme', which corresponds
     * to the file located at app/Theme.php. If you have moved this file or want
     * to use a different class name, update this value accordingly.
     */
    'theme_class' => 'App\\Theme',

    /**
     * Meros packages are discovered automatically from composer metadata.
     * List a provider here only to register one that isn't discoverable.
     */
    'packages' => [],
];
