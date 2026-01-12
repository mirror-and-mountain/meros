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
    'remote_environments' => []
];