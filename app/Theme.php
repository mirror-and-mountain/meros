<?php

namespace App;

use Illuminate\Support\Carbon;

use MM\Meros\App\Theme as MerosTheme;

class Theme extends MerosTheme {
    
    protected function configure(): void {
        $this->settingsTest();
        $this->fieldGroupsTest();

    }

    protected function fieldGroupsTest(): void {
        $group = $this->field_groups()->make(function ($group) {
            $group->handle('test_field-group')->title('Test Field Group');
            $group->description('This is a description for the test field group');

            $group->field('text', [
                'handle' => 'custom_text_field',
                'name' => 'custom_text_field',
            ])->width('half');

            $group->field('text', [
                'handle' => 'custom_text_field_2',
                'name'   => 'custom_text_field_2',
            ])->width('half')->required();

            $group->field('text', [
                'handle' => 'custom_text_field_3',
                'name' => 'custom_text_field_3',
            ])->width('full')->help('This is a help text for the full width field', 'top');

            $group->field('repeater', function($field) {
                $field->name('custom_repeater_field');

                $field->addField('text', [
                    'name'    => 'repeater_text_field',
                    'default' => 'Default Repeater Text',
                ]);

                $field->subField('number', [
                    'name'=> 'repeater_number_field',
                    'default' => 10,
                ]);
            })->default([
                ['repeater_text_field' => 'Repeater Row 1', 'repeater_number_field' => 10],
                ['repeater_text_field' => 'Repeater Row 2', 'repeater_number_field' => 5],
            ])->help('This is a help text for the repeater field', 'top')->width('half');

            $group->field('select', [
                'handle' => 'custom_select_field',
                'name' => 'custom_select_field'
            ])->options([
                'option1' => 'Option 1',
                'option2' => 'Option 2',
                'option3' => 'Option 3',
            ])->multiple()->advanced()->default(['option2'])->width('half')->help('This is a help text for the select field', 'top');
        });

        $form = $this->forms()->make(function ($form) use ($group) {
            $form->id('test-form');
            $form->title('Test Form');
            $form->attach($group);
        });

        // dd($form->toJson(true, JSON_PRETTY_PRINT));

        $this->menuPages()->make(function ($page) use ($form) {
            $page->slug('test-menu-page');
            $page->title('Test');
            $page->menuTitle('Test');
            $page->callback(function () use ($form) {
                echo '<h1>Test Menu Page</h1>';
                $form->render();
            });
        })->in('options');
    }

    protected function settingsTest(): void {
        $section = $this->settings_sections()->make(function ($section) {
            $section->id('test_settings_section');
            $section->title('Test Settings Section');
        });

        $this->settings()
            ->add()
            ->array('test_scalar_array')
            ->field()
                ->default(['Option 1', 'Option 2'])
                ->options(['option-3' => 'Option 3', 'option-4' => 'Option 4'])
                ->help('Some help text for the scalar array field')
                ->section($section);

        $section2 = $this->settings_sections()->make(function ($section) {
            $section->id('test_settings_section_2');
            $section->title('Test Settings Section 2');
            $section->callback(function () {
                echo '<p>This is a callback for the second test settings section.</p>';
            });
        });

        $this->settings()->add(function ($setting) use ($section2) {
            $setting->array('social_links')->configure(function ($setting) {
                $setting->add()->string('name')->label('Name')->field('text');
                $setting->add()->string('url')->label('URL')->field('url');
                $setting->add()->array('tags')->label('Tags')->field()->options([
                    'news' => 'News',
                    'blog' => 'Blog',
                    'social' => 'Social',
                ])->default(['social']);
                $setting->default([
                    ['name' => 'Facebook', 'url' => 'https://www.facebook.com/'],
                    ['name' => 'Twitter', 'url' => 'https://www.twitter.com/'],
                    ['name' => 'Instagram', 'url' => 'https://www.instagram.com/'],
                ]);
            })->field('repeater')->help('Some help text for the social links repeater field')->section($section2);
        });

        $this->settings()->add()->string('test_text')->field()->default('Default Text')->placeholder('Enter some text');
        $this->settings()->add()->number('test_number')->field()->placeholder('Enter a number')->step(5);

        $this->settings()->add()->string('test_radio')->field('radio')->options([
            'option1' => 'Option 1',
            'option2' => 'Option 2',
            'option3' => 'Option 3',
        ])->default('option2');

        $this->settings()->add()->string('test_select')->field('select')->options([
            'option1' => 'Option 1',
            'option2' => 'Option 2',
            'option3' => 'Option 3',
        ])->default('option2');

        $this->settings()->add()->boolean('test_boolean')->field('checkbox')->default(true);

        $this->settings()->add()->array('test_checkboxes')->field('checkboxes')->options([
            'option1' => 'Option 1',
            'option2' => 'Option 2',
            'option3' => 'Option 3',
        ])->default(['option1', 'option3']);

        $this->settings()->add()->string('test_textarea')->field('textarea')->default('Default Textarea Content')->rows(5);

        $default_date = Carbon::now()->format('Y-m-d');
        $default_time = Carbon::now()->format('H:i');

        $this->settings()->add()->string('test_date')->field('date')->default($default_date);
        $this->settings()->add()->string('test_time')->field('time')->default($default_time);
        $this->settings()->add()->string('test_color')->field('color')->default('#ff0000');

        // dd($this->settings());

        // $this->settings()->group('meros-features-meros')->onPage('meros-features-meros');
    }
}
