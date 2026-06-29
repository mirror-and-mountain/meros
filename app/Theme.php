<?php

namespace App;

use MM\Meros\App\Theme as MerosTheme;

use Illuminate\Support\Facades\Blade;

class Theme extends MerosTheme {
    
    protected function configure(): void {
        $this->testLivewire();

        $this->fieldGroups()->register('contact_information', function () {
            return $this->fieldGroups()->make(function ($fieldGroup) {
                $fieldGroup->title('Contact Information');
                $fieldGroup->row(function ($row) {
                    $row->field('text')->label('First Name');
                    $row->field('text')->label('Last Name');
                });

                $fieldGroup->row(function ($row) {
                    $row->field('email')->label('Email Address')->showIcon();
                    $row->field('tel')->label('Phone Number')->showIcon();
                });
            });
        });
    }

    private function testLivewire() {
        add_action('wp_head', function () {
            echo Blade::render('@livewireStyles');
        });

        add_action('wp_footer', function () {
            echo Blade::render('@livewireScripts');
        });
    }
}
