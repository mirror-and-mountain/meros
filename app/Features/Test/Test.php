<?php

namespace App\Features;

use MM\Meros\Contracts\Feature;

class Test extends Feature
{
    protected function configure(): void
    {
        $this->author   = 'Your Name';
        $this->category = 'miscellaneous';

        // Configure as needed
        // $this->hasAssets     = true;
        // $this->hasBlocks     = true;
        // $this->hasIncludes   = true;
        // $this->hasComponents = true;

        $this->enabled = true;
    }
}