<?php 

return [
    'default_options' => [
        'permalink_structure' => '/%postname%/',
    ],
    'clone_content' => [
        'exclude_tables' => [
            'comments',
            'commentmeta',
            'users',
            'usermeta',
            'options'
        ]
    ],
    'remote_environments' => [
        'dev' => [
            'url'  => 'https://test.mirrorandmountain.dev',
            'path' => 'public_html/mirrorandmountain.dev/test',
            'ssh'  => [
                'host' => '429d2e0d7d55068d98e7960945fad646-17866.sites.k-hosting.co.uk',
                'port' => '722',
                'user' => 'dedddef1',
                'key'  => 'MM_KRYS_001'
            ],
            'db'  => [
                'name'   => 'wordpress',
                'prefix' => 'wprd_'
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
            ]
        ]
    ]
];