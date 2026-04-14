<?php

namespace App;

use MM\Meros\App\Theme as MerosTheme;

use MM\Meros\App\Concerns\HasAssets;
use MM\Meros\App\Concerns\HasBlocks;

class Theme extends MerosTheme {
    
    use HasAssets, HasBlocks;

    protected function configure(): void {
        // Example of using the Discover class to automatically discover assets and enqueue them
        $this->discover()->assets();


        // Examples of using the enqueue method to enqueue assets with chained methods
        $this->enqueue()->script('/path/to/script.js')->handle('custom-script')->inFooter();
        $this->enqueue()->script('/path/to/script.js')->handle('custom-script')->inAdmin();
        $this->enqueue()->style('/path/to/style.css')->handle('custom-style')->inEditor();

        // Example of using the enqueue method with a closure to enqueue assets
        $this->enqueue()->script(function ($script) {
            $script->src('/path/to/script.js');
            $script->location('site');
            $script->handle('custom-script');
            $script->version('1.0.0');
            $script->inFooter();
        });

        // Example of using the Discover class to automatically discover blocks and register them
        $this->discover()->blocks();

        // Example of making a block via a path to a directory containing a block.json file
        $this->blocks()->make('meros/test')->path('/path/to/block');

        // Example of making a block using a closure
        $this->blocks()->make(function ($block) {
            $block->name('meros/hero');

            $block->title('Hero');

            $block->supports([
                'align'  => true,
                'anchor' => true,
            ]);

            $block->render(function ($attributes) {
                return view('blocks.hero', ['attributes' => $attributes]);
            });
        });

        // Example of making a block variation using chained methods
        $this->blocks()->make()->variation()->of('meros/test')->name('test-variation');
        
        // Example of making a block variation using a closure
        $this->blocks()->make()->variation(function ($variation) {
            $variation->parent('meros/hero');

            $variation->name('test');

            $variation->attributes([
                'attribute1' => 'value1',
                'attribute2' => 'value2',
            ]);       
        });

        // Example of making settings using a closure
        $this->settings(function ($settings) {
            
            // Example of a simple text setting with a field
            $settings->string('test_setting')->label('Test Setting');

            // Example of an array setting using a repeater field
            $settings->array('team_members')
                ->label('Team Members')
                ->description('Add team members to display on the site')
                ->default([
                    [
                        'name' => 'John Doe',
                        'email' => 'john.doe@example.com',
                        'role' => 'Developer',
                        'active' => true,
                    ],
                    [
                        'name' => 'Jane Smith',
                        'email' => 'jane.smith@example.com',
                        'role' => 'Designer',
                        'active' => false,
                    ]
                ])

                ->items(function ($items) {
                    $items
                        ->string('name')
                        ->label('Name')
                        ->field('text')
                        ->placeholder('John Doe');

                    $items
                        ->string('email')
                        ->label('Email')
                        ->field('email')
                        ->placeholder('john.doe@example.com');

                    $items
                        ->string('role')
                        ->label('Role')
                        ->field('select', [
                            'Developer' => 'Developer',
                            'Designer' => 'Designer',
                            'Manager' => 'Manager',
                            'Other' => 'Other',
                    ]);

                    $items
                        ->boolean('active')
                        ->label('Active');

                })->field('repeater')->layout('table');
        })
        ->autoFields()
        ->onPage('general');

        // dd($this->getSettings());
    }
}
