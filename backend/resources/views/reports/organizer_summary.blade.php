<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Organizer Activity Summary Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: DejaVu Sans, sans-serif; font-size: 10px; color: #1a1a2e; }
        .header { background: #1a237e; color: #fff; padding: 16px 20px; margin-bottom: 20px; }
        .header h1 { font-size: 16px; font-weight: bold; }
        .header p  { font-size: 10px; margin-top: 3px; opacity: 0.85; }
        .data-table { width: 100%; border-collapse: collapse; margin: 0 0 20px 0; }
        .data-table th { background: #3949ab; color: #fff; padding: 7px 8px; text-align: left; font-size: 9px; text-transform: uppercase; }
        .data-table td { padding: 6px 8px; border-bottom: 1px solid #e8eaf6; }
        .data-table tr:nth-child(even) td { background: #f3f4fb; }
        .footer { padding: 8px 20px; border-top: 1px solid #ddd; font-size: 9px; color: #888; }
    </style>
</head>
<body>
<div class="header">
    <h1>Organizer Activity Summary Report</h1>
    <p>Generated: {{ now()->format('F d, Y  h:i A') }} &nbsp;|&nbsp; By: {{ $generatedBy }}</p>
</div>
<table class="data-table">
    <thead>
        <tr>
            <th>#</th>
            <th>Organizer Email</th>
            <th>Status</th>
            <th>Events Organized</th>
            <th>Total Registrations</th>
            <th>Total Attendances</th>
        </tr>
    </thead>
    <tbody>
        @forelse($organizers as $i => $org)
        <tr>
            <td>{{ $i + 1 }}</td>
            <td>{{ $org->email }}</td>
            <td>{{ strtoupper($org->status) }}</td>
            <td>{{ $org->events_count ?? 0 }}</td>
            <td>{{ $org->total_registrations ?? 0 }}</td>
            <td>{{ $org->total_attendances ?? 0 }}</td>
        </tr>
        @empty
        <tr><td colspan="6" style="text-align:center; padding:20px; color:#888;">No organizers found.</td></tr>
        @endforelse
    </tbody>
</table>
<div class="footer">
    School Event Registration &amp; QR-Based Attendance Management System &nbsp;&bull;&nbsp; Confidential
</div>
</body>
</html>
