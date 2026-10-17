<?php

namespace App\Exports;

use App\Models\Event;
use App\Models\EventRegistration;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class RegistrationSummaryExport implements
    FromCollection,
    WithHeadings,
    WithMapping,
    WithStyles,
    WithTitle,
    ShouldAutoSize
{
    private int $row = 0;

    public function __construct(
        protected Event $event,
        protected string $generatedBy
    ) {}

    public function title(): string
    {
        return 'Registrations';
    }

    public function collection()
    {
        return EventRegistration::with('student')
            ->where('event_id', $this->event->id)
            ->orderBy('created_at', 'asc')
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
            'Registration Status',
            'Waiting List Position',
            'Registered At',
        ];
    }

    public function map($reg): array
    {
        $this->row++;

        return [
            $this->row,
            $reg->student?->student_id_number ?? '—',
            $reg->student?->full_name ?? '—',
            $reg->student?->course ?? '—',
            $reg->student?->department ?? '—',
            $reg->student?->year_level ?? '—',
            strtoupper($reg->status),
            $reg->waiting_list_position ?? '—',
            $reg->registered_at?->format('Y-m-d H:i:s') ?? '—',
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'font' => ['bold' => true, 'color' => ['argb' => 'FFFFFFFF']],
                'fill' => [
                    'fillType'   => Fill::FILL_SOLID,
                    'startColor' => ['argb' => 'FF1A237E'],
                ],
            ],
        ];
    }
}
