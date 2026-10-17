<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Institutional Participation Summary Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: DejaVu Sans, sans-serif; font-size: 10px; color: #1a1a2e; }
        .header { background: #1a237e; color: #fff; padding: 16px 20px; margin-bottom: 20px; }
        .header h1 { font-size: 16px; font-weight: bold; }
        .header p  { font-size: 10px; margin-top: 3px; opacity: 0.85; }
        .meta { padding: 0 20px; margin-bottom: 14px; }
        .meta table { width: 100%; border-collapse: collapse; }
        .meta td { padding: 3px 6px; vertical-align: top; }
        .meta td:first-child { font-weight: bold; width: 150px; color: #555; }
        .data-table { width: 100%; border-collapse: collapse; margin: 0 0 20px 0; }
        .data-table th { background: #3949ab; color: #fff; padding: 7px 8px; text-align: left; font-size: 9px; text-transform: uppercase; }
        .data-table td { padding: 6px 8px; border-bottom: 1px solid #e8eaf6; }
        .data-table tr:nth-child(even) td { background: #f3f4fb; }
        .footer { padding: 8px 20px; border-top: 1px solid #ddd; font-size: 9px; color: #888; }
    </style>
</head>
<body>
<div class="header">
    <h1>Institutional Participation Summary Report</h1>
    <p>Generated: {{ now()->format('F d, Y  h:i A') }} &nbsp;|&nbsp; By: {{ $generatedBy }}</p>
</div>
<div class="meta">
    <table>
        <tr><td>Total Events</td><td>{{ $summary['total_events'] }}</td></tr>
        <tr><td>Total Registrations</td><td>{{ $summary['total_registrations'] }}</td></tr>
        <tr><td>Total Attendances</td><td>{{ $summary['total_attendances'] }}</td></tr>
        <tr><td>Overall Turnout</td><td>{{ $summary['turnout_percentage'] }}%</td></tr>
    </table>
</div>
<table class="data-table">
    <thead>
        <tr>
            <th>#</th>
            <th>Event Title</th>
            <th>Date</th>
            <th>Venue</th>
            <th>Status</th>
            <th>Registered</th>
            <th>Attended</th>
        </tr>
    </thead>
    <tbody>
        @forelse($events as $i => $ev)
        <tr>
            <td>{{ $i + 1 }}</td>
            <td>{{ $ev->title }}</td>
            <td>{{ $ev->event_date?->format('Y-m-d') }}</td>
            <td>{{ $ev->venue }}</td>
            <td>{{ strtoupper($ev->status) }}</td>
            <td>{{ $ev->registered_count ?? 0 }}</td>
            <td>{{ $ev->attended_count ?? 0 }}</td>
        </tr>
        @empty
        <tr><td colspan="7" style="text-align:center; padding:20px; color:#888;">No events found.</td></tr>
        @endforelse
    </tbody>
</table>
<div class="footer">
    School Event Registration &amp; QR-Based Attendance Management System &nbsp;&bull;&nbsp; Confidential
</div>
</body>
</html>
