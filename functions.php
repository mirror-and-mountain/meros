<?php

$theme_path = get_theme_file_path();
$autoloader = wp_normalize_path( $theme_path . '/vendor/autoload.php' );

require_once( $autoloader );

if ( class_exists( 'MM\\Meros\\Bootstrap' ) ) {
    MM\Meros\Bootstrap::bootstrap();
};

add_action( 'enqueue_block_editor_assets', function () {
    wp_enqueue_code_editor( [
        'type' => 'text/html',
    ] );
} );


