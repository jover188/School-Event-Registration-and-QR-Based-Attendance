<?php

namespace App\Exports;

use App\Models\Attendance;
use App\Models\EventRegistration;
use App\Models\User;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class OrganizerSummaryExport implements
    FromCollection,
    WithHeadings,
    WithMapping,
    WithStyles,
    WithTitle,
    ShouldAutoSize
{
    private int $row = 0;

    public function __construct(
        protected string $generatedBy,
        protected ?string $dateFrom = null,
        protected ?string $dateTo = null
    ) {}

    public function title(): string
    {
        return 'Organizer Summary';
    }

    public function collection()
    {
        return User::where('role_id', 2)
            ->get()
            ->map(function (User $organizer) {
                $eventsQuery = $organizer->organizedEvents();
                if ($this->dateFrom) {
                    $eventsQuery->where('event_date', '>=', $this->dateFrom);
                }
                if ($this->dateTo) {
                    $eventsQuery->where('event_date', '<=', $this->dateTo);
                }
                $eventIds = $eventsQuery->pluck('id');
                $organizer->events_count = $eventIds->count();
                $organizer->total_registrations = EventRegistration::whereIn('event_id', $eventIds)
                    ->where('status', 'registered')
                    ->count();
                $organizer->total_attendances = Attendance::whereIn('event_id', $eventIds)
                    ->where('status', '!=', 'absent')
                    ->count();
                return $organizer;
            });
    }

    public function headings(): array
    {
        return [
            '#',
            'Organizer Email',
            'Status',
            'Total Events Organized',
            'Total Registrations',
            'Total Attendances',
            'Turnout (%)',
        ];
    }

    public function map($organizer): array
    {
        $this->row++;
        $regCount = (int) $organizer->total_registrations;
        $attCount = (int) $organizer->total_attendances;
        $turnout  = $regCount > 0 ? round(($attCount / $regCount) * 100, 2) . '%' : '0%';

        return [
            $this->row,
            $organizer->email,
            strtoupper($organizer->status),
            (int) $organizer->events_count,
            $regCount,
            $attCount,
            $turnout,
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
