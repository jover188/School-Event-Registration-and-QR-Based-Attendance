<?php

namespace App\Exports;

use App\Models\Attendance;
use App\Models\Event;
use App\Models\EventRegistration;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class EventAttendanceExport implements
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
        return 'Attendance';
    }

    public function collection(): Collection
    {
        $attendances = Attendance::with('student')
            ->where('event_id', $this->event->id)
            ->orderBy('check_in_time', 'asc')
            ->get();

        $absentees = EventRegistration::with('student')
            ->where('event_id', $this->event->id)
            ->where('status', 'registered')
            ->whereDoesntHave('attendance')
            ->get()
            ->map(function ($reg) {
                return (object) [
                    'student'        => $reg->student,
                    'status'         => 'absent',
                    'check_in_time'  => null,
                    'check_out_time' => null,
                ];
            });

        return $attendances->concat($absentees);
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
        $this->row++;

        return [
            $this->row,
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
