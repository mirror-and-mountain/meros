<?php

namespace App\Extensions;

use MM\Meros\DynamicPage\Feature as Feature;

class MerosDynamicPage extends Feature
{
    protected function override(): void
    {
        $this->enabled = true;
    }
}