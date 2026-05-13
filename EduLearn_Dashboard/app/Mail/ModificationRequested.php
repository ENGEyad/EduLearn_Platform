<?php

namespace App\Mail;

use App\Models\School;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ModificationRequested extends Mailable
{
    use Queueable, SerializesModels;

    public $school;
    public $instructions;

    /**
     * Create a new message instance.
     */
    public function __construct(School $school, string $instructions)
    {
        $this->school = $school;
        $this->instructions = $instructions;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Action required: Modification requested for your school registration',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.modification_requested',
        );
    }
}
