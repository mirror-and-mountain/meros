<?php

require __DIR__ . '/vendor/autoload.php';

foreach ([
    'meros-foundations',
    'meros-framework',
    'meros-crm',
    'meros-blocks',
    'meros-email-connectors',
] as $package) {
    MM\Meros\Foundations\Testing\Bootstrap::load(Composer\InstalledVersions::getInstallPath('mirror-and-mountain/' . $package));
}
