<?php

namespace App\Exports;

use App\Models\Event;
use App\Models\EventRegistration;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;

class AbsenteeExport implements
    FromCollection,
    WithHeadings,
    WithMapping,
    WithStyles,
    WithTitle,
    ShouldAutoSize
{
    public function __construct(
        protected Event $event,
        protected string $generatedBy
    ) {}

    public function title(): string
    {
        return 'Absentees';
    }

    public function collection()
    {
        return EventRegistration::with('student')
            ->where('event_id', $this->event->id)
            ->where('status', 'registered')
            ->whereDoesntHave('attendance')
            ->get();
    }

    public function headings(): array
    {
        return [
            '#',
            'Student ID',
            'Full Name',
            'Course',
            'Department',
            'Year Level',
            'Contact Number',
            'Email',
        ];
    }

    public function map($reg): array
    {
        static $row = 0;
        $row++;

        return [
            $row,
            $reg->student?->student_id_number ?? '—',
            $reg->student?->full_name ?? '—',
            $reg->student?->course ?? '—',
            $reg->student?->department ?? '—',
            $reg->student?->year_level ?? '—',
            $reg->student?->contact_number ?? '—',
            $reg->student?->user?->email ?? '—',
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'font' => ['bold' => true, 'color' => ['argb' => 'FFFFFFFF']],
                'fill' => [
                    'fillType'   => Fill::FILL_SOLID,
                    'startColor' => ['argb' => 'FFC62828'],
                ],
            ],
        ];
    }
}
