<?php

namespace App\Extensions;

use MM\Meros\Forms\Feature as Feature;

class MerosForms extends Feature
{
    protected function override(): void
    {
        $this->enabled = true;
    }
}