<?php 

return [
    /**
     * The options defined here will be set in the wp_options table when 
     * the local environment is initialised for the first time.
     * 
     */
    'local_options' => [
        'blog_public' => 0,
    ],

    /**
     * The remote environments that can be connected to and deployed to.
     * Each environment should have its own configuration defined here.
     * 
     * Config:
     * - url:     The URL of the environment. Used when connecting to the environment and for reference when deploying.
     * - path:    The path to the WordPress installation on the remote server. Used when connecting to the environment and for reference when deploying.
     * - ssh:     The SSH configuration for connecting to the remote server. Used when connecting to the environment and when deploying.
     * - db:      The database configuration for the environment. Used when deploying to ensure the correct prefix is used when syncing the database between environments.
     * - options: WordPress options to update in the wp_options table on the remote environment when deploying. The key is the option name and the value is the option value.
     */
    'remote_environments' => [
        'development' => [
            'url'  => 'https://dev.example.com',
            'path' => 'path/to/wordpress',
            'ssh'  => [
                'host' => 'example.com',
                'port' => '22',
                'user' => 'username',
                'key'  => 'ida_rsa_example'
            ],
            'db'  => [
                'name'   => 'wordpress',
                'prefix' => 'wp_'
            ]
        ],
        'staging' => [
            'url'  => 'https://staging.example.com',
            'path' => 'path/to/wordpress',
            'ssh'  => [
                'host' => 'example.com',
                'port' => '22',
                'user' => 'username',
                'key'  => 'ida_rsa_example'
            ],
            'db'  => [
                'name'   => 'wordpress',
                'prefix' => 'wp_'
            ]
        ],
        'production' => [
            'url'  => 'https://example.com',
            'path' => 'path/to/wordpress',
            'ssh'  => [
                'host' => 'example.com',
                'port' => '22',
                'user' => 'username',
                'key'  => 'ida_rsa_example'
            ],
            'db'  => [
                'name'   => 'wordpress',
                'prefix' => 'wp_'
            ],
            'options' => [
                'blog_public' => 1,
            ]
        ]
    ],

    /**
     * The configuration for syncing between environments.
     * This is used when running the `wp meros:env sync` command to determine what should be synced between environments.
     * 
     */
    'sync_templates' => [
        /**
         * The default sync configuration used when syncing between environments where no specific configuration is defined. 
         * See 'specific sync configurations' below. Note that the theme is always synchronised between environments.
         * 
         */
        'default' => [
            /** 
             * Note that you may need to specify additional tables here depending on any plugins or packages your site uses.
             * For example, if you use WooCommerce, you would need to include the WooCommerce tables here to ensure that product data is synced between environments.
             * By default, unlisted tables will not be synchronised between environments, so the 'false' values here are really only used for reference.
             * 
             */
            'tables' => [
                'posts'              => true,
                'postmeta'           => true,
                'comments'           => true,
                'commentmeta'        => true,
                'links'              => true,
                'terms'              => true,
                'termmeta'           => true,
                'term_taxonomy'      => true,
                'term_relationships' => true,
                'users'              => false,
                'usermeta'           => false,
                'options'            => false, // Specific options can be synced using the 'options' key below
            ],

            'uploads' => true, // Whether to sync the uploads directory between environments. Should usually be set to true if syncing the posts table to ensure attachment media is synced.
            'plugins' => true, // May also be set to an array of specific plugins to sync or ignore.

            // Options specified here will be updated in the wp_options table on the destination environment after syncing.
            'options' => [
                'theme_mods'
            ]
        ],

        /**
         * You can specify specific sync configuration for syncing between two environments.
         * Ensure that the array key here is formatted as 'sourceEnvironment_to_destinationEnvironment'.
         * 
         */
        'local_to_development' => [
            'tables' => [
                'posts'              => true,
                'postmeta'           => true,
                'comments'           => true,
                'commentmeta'        => true,
                'links'              => true,
                'terms'              => true,
                'termmeta'           => true,
                'term_taxonomy'      => true,
                'term_relationships' => true,
                'users'              => false,
                'usermeta'           => false,
                'options'            => false,
            ],

            'uploads' => true,
            'plugins' => true,

            'options' => [
                'theme_mods'
            ]
        ],

        // An example of a sync configuration between the development and staging environments.
        'development_to_staging' => [
            'tables' => [
                'posts'              => true,
                'postmeta'           => true,
                'comments'           => true,
                'commentmeta'        => true,
                'links'              => true,
                'terms'              => true,
                'termmeta'           => true,
                'term_taxonomy'      => true,
                'term_relationships' => true,
                'users'              => false,
                'usermeta'           => false,
                'options'            => false,
            ],

            'uploads' => true,
            'plugins' => [
                'create-block-theme' => false, // Example of how to exclude a specific plugin from syncing. All other plugins will be synced.
            ],

            'options' => [
                'theme_mods'
            ]
        ],

        // An example of a configuration where the 'staging' environment is used as a complete mirror of the production environment.
        'staging_to_production' => [
            'tables' => [
                'posts'              => true,
                'postmeta'           => true,
                'comments'           => true,
                'commentmeta'        => true,
                'links'              => true,
                'terms'              => true,
                'termmeta'           => true,
                'term_taxonomy'      => true,
                'term_relationships' => true,
                'users'              => true,
                'usermeta'           => true,
                'options'            => true,
            ],

            'uploads' => true,
            'plugins' => true,
        ]
    ]
];