<?php

namespace App;

use Illuminate\Support\Str;

use MM\Meros\Contracts\Features\Content\PostType;
use MM\Meros\Contracts\Features\Content\Interfaces\FormHost;
use MM\Meros\Contracts\Features\Content\Concerns\UsesForms;
use MM\Meros\Facades\Components\Forms;

use MM\Meros\Contracts\Features\Components\Form as FormComponent;
use MM\Meros\Contracts\Features\Components\FieldGroup as FieldGroupComponent;

use MM\Meros\App\Models\Post;

class Event extends PostType implements FormHost {
    use UsesForms;

    protected function configure(): void {
        $this->handle('event');
        $this->label('Event', 'Events');
        $this->public();
        $this->menuIcon('dashicons-feedback');

        $this->hasEditableForm()
            ->withConfigurableTemplate('event-registration-form', function (FormComponent $form) {
                $form->section(function (FieldGroupComponent $section) {
                    $section->id('event-registration-contact-information');
                    $section->title('Contact Information');

                    $section->field('text', [
                        'name' => 'first_name',
                        'label' => 'First Name',
                        'required' => true,
                        'lock' => true
                    ]); 

                    $section->field('text', [
                        'name' => 'last_name',
                        'label' => 'Last Name',
                        'required' => true,
                        'lock' => true
                    ]);

                    $section->field('email', [
                        'name' => 'email',
                        'label' => 'Email',
                        'required' => true,
                        'lock' => true
                    ]);
                });
            }, [], [
                'allow_remove_components' => false
            ])
            ->withActionsEditor()
            ->withFormSettings();
    }
}