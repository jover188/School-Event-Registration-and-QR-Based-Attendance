<?php

namespace App\Exports;

use App\Models\Event;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ParticipationSummaryExport implements
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
        return 'Participation Summary';
    }

    public function collection()
    {
        $query = Event::whereIn('status', ['published', 'ongoing', 'completed'])
            ->withCount([
                'registrations as registered_count' => fn ($q) => $q->where('status', 'registered'),
                'attendances as attended_count' => fn ($q) => $q->where('status', '!=', 'absent'),
            ])
            ->orderBy('event_date', 'desc');

        if ($this->dateFrom) {
            $query->where('event_date', '>=', $this->dateFrom);
        }
        if ($this->dateTo) {
            $query->where('event_date', '<=', $this->dateTo);
        }

        return $query->get();
    }

    public function headings(): array
    {
        return [
            '#',
            'Event Title',
            'Event Date',
            'Venue',
            'Status',
            'Registered Count',
            'Attended Count',
            'Turnout (%)',
        ];
    }

    public function map($event): array
    {
        $this->row++;
        $regCount = (int) $event->registered_count;
        $attCount = (int) $event->attended_count;
        $turnout  = $regCount > 0 ? round(($attCount / $regCount) * 100, 2) . '%' : '0%';

        return [
            $this->row,
            $event->title,
            $event->event_date?->format('Y-m-d') ?? '—',
            $event->venue,
            strtoupper($event->status),
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
