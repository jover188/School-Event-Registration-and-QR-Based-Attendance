<?php

namespace App\Exports;

use App\Models\Attendance;
use App\Models\Event;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Color;

class EventAttendanceExport implements
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
        return 'Attendance';
    }

    public function collection()
    {
        return Attendance::with('student')
            ->where('event_id', $this->event->id)
            ->orderBy('check_in_time', 'asc')
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
            'Status',
            'Check-In Time',
            'Check-Out Time',
        ];
    }

    public function map($att): array
    {
        static $row = 0;
        $row++;

        return [
            $row,
            $att->student?->student_id_number ?? '—',
            $att->student?->full_name ?? '—',
            $att->student?->course ?? '—',
            $att->student?->department ?? '—',
            $att->student?->year_level ?? '—',
            strtoupper($att->status),
            $att->check_in_time?->format('Y-m-d H:i:s') ?? '—',
            $att->check_out_time?->format('Y-m-d H:i:s') ?? 'N/A',
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            // Header row bold + navy background
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
