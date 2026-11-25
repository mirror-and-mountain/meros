<?php

namespace App;

use MM\Meros\App\BaseTheme;

class Theme extends BaseTheme {
    public function configure(): void {
        // Test form post type
        $this->postTypes(Event::class)->make();
    }
}
