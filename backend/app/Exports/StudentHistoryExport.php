<?php

namespace App\Exports;

use App\Models\Attendance;
use App\Models\Student;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class StudentHistoryExport implements
    FromCollection,
    WithHeadings,
    WithMapping,
    WithStyles,
    WithTitle,
    ShouldAutoSize
{
    private int $row = 0;

    public function __construct(
        protected Student $student,
        protected string $generatedBy
    ) {}

    public function title(): string
    {
        return 'Student History';
    }

    public function collection()
    {
        return Attendance::with('event')
            ->where('student_id', $this->student->id)
            ->orderBy('check_in_time', 'desc')
            ->get();
    }

    public function headings(): array
    {
        return [
            '#',
            'Event Title',
            'Event Date',
            'Venue',
            'Status',
            'Check-In Time',
            'Check-Out Time',
        ];
    }

    public function map($att): array
    {
        $this->row++;

        return [
            $this->row,
            $att->event?->title ?? '—',
            $att->event?->event_date?->format('Y-m-d') ?? '—',
            $att->event?->venue ?? '—',
            strtoupper($att->status),
            $att->check_in_time?->format('Y-m-d H:i:s') ?? '—',
            $att->check_out_time?->format('Y-m-d H:i:s') ?? 'N/A',
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
