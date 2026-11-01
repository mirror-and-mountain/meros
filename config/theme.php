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
     * The following array stores service providers needed to bootstrap
     * your theme's packages. 
     * 
     * It is updated automatically when either a new package is installed or 
     * an existing one is removed.
     */
    'packages' => [
        'MM\\Meros\\Blocks\\ServiceProvider',
        'MM\\Meros\\Crm\\ServiceProvider',
    ]
];

