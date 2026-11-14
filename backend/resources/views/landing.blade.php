<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  
  <title>Attendify — Smarter Events. Seamless Attendance.</title>
  <meta name="description" content="School Event Registration and QR-Based Attendance Management System with permanent QR codes, automated capacity management, and real-time auditable reporting.">
  
  <!-- OpenGraph / Social Meta Tags -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="Attendify — Smarter Events. Seamless Attendance.">
  <meta property="og:description" content="Decoupled client-server institutional platform for student event registration, sub-second QR attendance scanning, and real-time auditable reporting.">
  <meta property="og:image" content="{{ asset('images/logo.png') }}">
  <meta property="og:url" content="{{ url('/') }}">
  
  <!-- Favicon -->
  <link rel="icon" type="image/svg+xml" href="{{ asset('favicon.svg') }}?v=1.1.0">
  <link rel="icon" type="image/png" sizes="32x32" href="{{ asset('favicon.png') }}?v=1.1.0">
  <link rel="shortcut icon" href="{{ asset('favicon.ico') }}?v=1.1.0">
  <link rel="apple-touch-icon" href="{{ asset('icons/Icon-192.png') }}?v=1.1.0">
  
  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  
  <!-- Custom Minimalist Stylesheet -->
  <link rel="stylesheet" href="{{ asset('css/landing.css') }}">
</head>
<body>
  <!-- Accessibility Skip Link -->
  <a href="#main-content" class="skip-to-content">Skip to content</a>

  <!-- ── Header / Navigation ───────────────────────────────── -->
  <header class="navbar" role="banner">
    <div class="container nav-container">
      <a href="#home" class="nav-brand" aria-label="Attendify Home">
        <img src="{{ asset('images/logo_icon.svg') }}" alt="Attendify Mark" width="32" height="32" onerror="this.src='{{ asset('images/logo_mark.png') }}'">
        <span>Attendify</span>
      </a>

      <!-- Desktop Navigation Links -->
      <nav class="nav-menu" role="navigation" aria-label="Primary Navigation">
        <ul class="nav-links">
          <li><a href="#home" class="nav-link active">Home</a></li>
          <li><a href="#about" class="nav-link">About</a></li>
          <li><a href="#features" class="nav-link">Features</a></li>
          <li><a href="#how-it-works" class="nav-link">How It Works</a></li>
          <li><a href="#preview" class="nav-link">Preview</a></li>
          <li><a href="#download" class="nav-link">Download</a></li>
        </ul>
      </nav>

      <!-- Action Buttons -->
      <div class="nav-actions">
        <a href="{{ url('/app') }}" class="btn btn-secondary btn-sm" title="Open Attendify in your browser">
          <span>Open Web App</span>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
        </a>
        <a href="#download" class="btn btn-primary btn-sm">Get Started</a>
      </div>

      <!-- Mobile Hamburger Toggle -->
      <button class="mobile-menu-btn" id="mobileMenuToggle" aria-label="Toggle navigation menu" aria-expanded="false">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7"/>
        </svg>
      </button>
    </div>
  </header>

  <!-- Mobile Navigation Overlay -->
  <div class="mobile-nav-overlay" id="mobileNavOverlay" role="dialog" aria-modal="true" aria-label="Mobile Navigation">
    <ul class="mobile-nav-links">
      <li><a href="#home" class="mobile-nav-link">Home</a></li>
      <li><a href="#about" class="mobile-nav-link">About</a></li>
      <li><a href="#features" class="mobile-nav-link">Features</a></li>
      <li><a href="#how-it-works" class="mobile-nav-link">How It Works</a></li>
      <li><a href="#preview" class="mobile-nav-link">Preview</a></li>
      <li><a href="#download" class="mobile-nav-link">Download APK</a></li>
    </ul>
    <div style="display: flex; flex-direction: column; gap: 12px; margin-top: auto;">
      <a href="{{ url('/app') }}" class="btn btn-secondary" style="width: 100%;">Open Web App</a>
      <a href="{{ url('/download/apk') }}" download="attendify-release.apk" class="btn btn-primary mobile-nav-action" style="width: 100%;">Download Android App</a>
    </div>
  </div>

  <main id="main-content">
    <!-- ── Hero Section ──────────────────────────────────────── -->
    <section class="hero" id="home">
      <div class="hero-glow"></div>
      <div class="container hero-content">
        <div class="hero-pill">
          <span class="hero-pill-dot"></span>
          <span>Attendify v1.1 • Production Ready on Render & Android</span>
        </div>

        <h1 class="hero-title">Smarter Events.<br>Seamless Attendance.</h1>

        <p class="hero-subtitle">
          The institutional platform for school event registration and sub-second QR-based attendance tracking. Built with permanent cryptographic student QR codes, automated waiting list management, and audit-ready reporting.
        </p>

        <div class="hero-cta">
          <a href="{{ url('/download/apk') }}" download="attendify-release.apk" class="btn btn-primary btn-lg">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>
            <span>Download Attendify APK</span>
          </a>
          <a href="{{ url('/app') }}" class="btn btn-secondary btn-lg">
            <span>Launch Web App</span>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
          </a>
        </div>

        <!-- Application Showcase Frame -->
        <div class="hero-preview">
          <div class="preview-frame">
            <div class="preview-topbar">
              <div class="preview-dots">
                <span class="preview-dot"></span>
                <span class="preview-dot"></span>
                <span class="preview-dot"></span>
              </div>
              <span class="preview-title-bar">Attendify Mobile & Web App Interface</span>
              <span style="font-size: 0.75rem; color: var(--status-green); font-family: var(--font-mono);">● LIVE</span>
            </div>

            <div class="preview-grid">
              <!-- Replica of Real Student QR Card -->
              <div class="qr-card-mockup">
                <span class="qr-card-badge">Permanent ID</span>
                <div class="qr-avatar">JD</div>
                <h4 class="qr-name">Juan Dela Cruz</h4>
                <div class="qr-id">Student ID: 20260001</div>
                <div class="qr-meta">BS Computer Science • 3rd Year (CS-3A)</div>

                <div class="qr-box">
                  <!-- Vector QR Code representation -->
                  <svg viewBox="0 0 100 100" fill="currentColor">
                    <!-- Position markers -->
                    <rect x="0" y="0" width="28" height="28" rx="4" fill="#000"/>
                    <rect x="4" y="4" width="20" height="20" rx="2" fill="#fff"/>
                    <rect x="8" y="8" width="12" height="12" rx="1" fill="#000"/>

                    <rect x="72" y="0" width="28" height="28" rx="4" fill="#000"/>
                    <rect x="76" y="4" width="20" height="20" rx="2" fill="#fff"/>
                    <rect x="80" y="8" width="12" height="12" rx="1" fill="#000"/>

                    <rect x="0" y="72" width="28" height="28" rx="4" fill="#000"/>
                    <rect x="4" y="76" width="20" height="20" rx="2" fill="#fff"/>
                    <rect x="8" y="80" width="12" height="12" rx="1" fill="#000"/>

                    <!-- Data modules -->
                    <rect x="36" y="4" width="8" height="8" fill="#000"/>
                    <rect x="48" y="12" width="8" height="8" fill="#000"/>
                    <rect x="36" y="24" width="8" height="8" fill="#000"/>
                    <rect x="12" y="36" width="8" height="8" fill="#000"/>
                    <rect x="24" y="44" width="8" height="8" fill="#000"/>
                    <rect x="36" y="36" width="28" height="28" rx="3" fill="#000"/>
                    <rect x="44" y="44" width="12" height="12" rx="1" fill="#fff"/>
                    <rect x="72" y="36" width="8" height="8" fill="#000"/>
                    <rect x="84" y="48" width="8" height="8" fill="#000"/>
                    <rect x="36" y="72" width="8" height="8" fill="#000"/>
                    <rect x="48" y="80" width="8" height="8" fill="#000"/>
                    <rect x="72" y="72" width="16" height="8" fill="#000"/>
                    <rect x="72" y="84" width="8" height="16" fill="#000"/>
                  </svg>
                </div>
                <div class="qr-token-text">a1b2c3d4e5f60718293a4b5c6d7e8f90...</div>
                <div style="font-size: 0.7rem; color: var(--text-muted); margin-top: 6px;">Zero-PII 64-char Hex Token</div>
              </div>

              <!-- Replica of Live Campus Event Card -->
              <div class="event-card-mockup">
                <div>
                  <div class="event-header-row">
                    <span class="event-tag">Published • Ongoing</span>
                    <span style="font-size: 0.8rem; color: var(--text-muted); font-family: var(--font-mono);">Nov 14, 2026</span>
                  </div>
                  <h3 class="event-title">Annual University Technology Summit 2026</h3>
                  <div class="event-info-list">
                    <div class="event-info-item">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                      <span>University Gymnasium & Auditorium</span>
                    </div>
                    <div class="event-info-item">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                      <span>08:00 AM – 05:00 PM (15m Grace Period)</span>
                    </div>
                    <div class="event-info-item">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                      <span>Organizer: College of Computer Studies</span>
                    </div>
                  </div>
                </div>

                <div>
                  <div class="capacity-tracker">
                    <div class="capacity-labels">
                      <span>Live Capacity</span>
                      <strong style="color: var(--accent-white);">82 / 100 Students</strong>
                    </div>
                    <div class="progress-bar-bg">
                      <div class="progress-bar-fill"></div>
                    </div>
                  </div>
                  <div style="display: flex; gap: 8px;">
                    <span class="btn btn-primary btn-sm" style="flex: 1; pointer-events: none;">Registered</span>
                    <span class="btn btn-secondary btn-sm" style="pointer-events: none;">QR Ready</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Metrics Bar -->
        <div class="stats-bar">
          <div class="stat-item">
            <div class="stat-number">100%</div>
            <div class="stat-label">PII-Free QR Security</div>
          </div>
          <div class="stat-item">
            <div class="stat-number">&lt; 0.5s</div>
            <div class="stat-label">QR Check-in Scan Speed</div>
          </div>
          <div class="stat-item">
            <div class="stat-number">4 Roles</div>
            <div class="stat-label">Strict Multi-Tier RBAC</div>
          </div>
          <div class="stat-item">
            <div class="stat-number">7 Types</div>
            <div class="stat-label">Audit-Ready Reports</div>
          </div>
        </div>
      </div>
    </section>

    <!-- ── About Section ─────────────────────────────────────── -->
    <section class="section section-alt" id="about">
      <div class="container">
        <div class="section-header">
          <span class="section-tag">About Attendify</span>
          <h2 class="section-title">Institutional Event Governance, Built for Modern Schools.</h2>
          <p class="section-desc">
            Attendify replaces paper sign-up sheets, long lines, and fragmented attendance tracking with an enterprise-grade platform tailored for colleges, universities, and student councils.
          </p>
        </div>

        <div class="about-grid">
          <div class="about-card">
            <div class="about-card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
            </div>
            <h3 class="about-card-title">Permanent QR Identity</h3>
            <p class="about-card-desc">
              Every student is assigned one permanent 64-character cryptographic hexadecimal token. Zero personal contact information or academic records are embedded inside the QR code, ensuring complete data privacy even if intercepted.
            </p>
          </div>

          <div class="about-card">
            <div class="about-card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            </div>
            <h3 class="about-card-title">SIS Roster Synchronization</h3>
            <p class="about-card-desc">
              Accounts are pre-provisioned directly from the registrar's Student Information System. Open self-registration is disabled to eliminate fake accounts. Students log in instantly with their verified Student ID number.
            </p>
          </div>

          <div class="about-card">
            <div class="about-card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <h3 class="about-card-title">Multi-Tier Lifecycle Approval</h3>
            <p class="about-card-desc">
              Event organizers draft activities and submit them for administrative review. No event goes live until an Administrator validates venue capacity, date conflicts, and safety requirements, creating a complete audit trail.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Features Section ──────────────────────────────────── -->
    <section class="section" id="features">
      <div class="container">
        <div class="section-header">
          <span class="section-tag">System Capabilities</span>
          <h2 class="section-title">Everything Needed to Run Campus Events Flawlessly.</h2>
          <p class="section-desc">
            Seven core modules engineered to handle high-concurrency event registrations, multi-gate attendance scanning, and auditable governance.
          </p>
        </div>

        <div class="features-grid">
          <!-- 1. Event Management -->
          <div class="feature-card">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            </div>
            <h3 class="feature-title">Event Management</h3>
            <p class="feature-desc">
              Full lifecycle management from draft creation and admin approval submission to cancellation requests, venue scheduling, and attendee caps.
            </p>
          </div>

          <!-- 2. QR Code Attendance -->
          <div class="feature-card">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><rect x="7" y="7" width="10" height="10" rx="1"/></svg>
            </div>
            <h3 class="feature-title">QR Code Attendance</h3>
            <p class="feature-desc">
              High-speed camera scanning supporting both Check-In and Check-Out. Automatically marks Present, Late (grace period), or Walk-In.
            </p>
          </div>

          <!-- 3. Event Registration -->
          <div class="feature-card">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/><path d="m9 14 2 2 4-4"/></svg>
            </div>
            <h3 class="feature-title">Event Registration &amp; Waiting List</h3>
            <p class="feature-desc">
              One-tap student registration with capacity tracking. When slots fill up, students join an automated FIFO waiting list promoted upon cancellations.
            </p>
          </div>

          <!-- 4. Real-Time Monitoring -->
          <div class="feature-card">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
            </div>
            <h3 class="feature-title">Real-Time Attendance Monitoring</h3>
            <p class="feature-desc">
              Live dashboard updating attendee tallies in real time. Authorized staff can review check-in timestamps, correct errors, and record reasons.
            </p>
          </div>

          <!-- 5. Push Notifications -->
          <div class="feature-card">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            </div>
            <h3 class="feature-title">Audible &amp; Push Notifications</h3>
            <p class="feature-desc">
              Firebase Cloud Messaging (FCM) integration with custom SFXMint chime sound alerts for announcements, 24h/1h reminders, and cancellations.
            </p>
          </div>

          <!-- 6. Student Management -->
          <div class="feature-card">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
            </div>
            <h3 class="feature-title">Student Management</h3>
            <p class="feature-desc">
              Immutable institutional records with department and course tracking. Administrator tools for QR inspection, instant reissue, and profile audits.
            </p>
          </div>

          <!-- 7. Calendar & Event Scheduling -->
          <div class="feature-card" style="grid-column: span 1;">
            <div class="feature-icon-wrapper">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><circle cx="12" cy="15" r="1"/></svg>
            </div>
            <h3 class="feature-title">Calendar &amp; Event Scheduling</h3>
            <p class="feature-desc">
              Interactive month-view calendar with status badges, event conflict warnings, and synchronized start/end time countdowns.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── How It Works Section ──────────────────────────────── -->
    <section class="section section-alt" id="how-it-works">
      <div class="container">
        <div class="section-header">
          <span class="section-tag">Workflow</span>
          <h2 class="section-title">How Attendify Works in 5 Simple Steps.</h2>
          <p class="section-desc">
            A frictionless journey from student login to official attendance recording and institutional export.
          </p>
        </div>

        <div class="steps-container">
          <div class="step-card">
            <div class="step-num">1</div>
            <h4 class="step-title">Students Log In</h4>
            <p class="step-desc">Students authenticate using their official Student ID number or institutional email with single-session security.</p>
          </div>

          <div class="step-card">
            <div class="step-num">2</div>
            <h4 class="step-title">Discover & Register</h4>
            <p class="step-desc">Students explore approved events on the interactive calendar and secure their slot with one-tap registration.</p>
          </div>

          <div class="step-card">
            <div class="step-num">3</div>
            <h4 class="step-title">Attend the Event</h4>
            <p class="step-desc">Students arrive at the venue and present their permanent in-app QR code (accessible completely offline).</p>
          </div>

          <div class="step-card">
            <div class="step-num">4</div>
            <h4 class="step-title">Organizers Scan</h4>
            <p class="step-desc">Authorized event staff scan student QR passes with the mobile camera, performing sub-second validation.</p>
          </div>

          <div class="step-card">
            <div class="step-num">5</div>
            <h4 class="step-title">Attendance Recorded</h4>
            <p class="step-desc">Records are permanently logged into the database, generating downloadable PDF and Excel compliance reports.</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Application Preview Section ───────────────────────── -->
    <section class="section" id="preview">
      <div class="container">
        <div class="section-header">
          <span class="section-tag">Application Preview</span>
          <h2 class="section-title">Tailored Experiences for Every Campus Role.</h2>
          <p class="section-desc">
            Explore the authentic interfaces built for students, organizers, and school management.
          </p>
        </div>

        <!-- Role Tabs -->
        <div class="preview-role-tabs">
          <button class="role-tab-btn active" data-role="student">Student Portal</button>
          <button class="role-tab-btn" data-role="organizer">Organizer Scanner</button>
          <button class="role-tab-btn" data-role="admin">Admin Dashboard</button>
        </div>

        <!-- Student Tab Panel -->
        <div class="preview-role-panel active" id="role-panel-student">
          <div class="role-showcase-box">
            <div class="role-details">
              <h3>Student Experience</h3>
              <p>
                Students enjoy a clean, distraction-free portal designed to access their permanent QR pass, track registered events, and monitor attendance records.
              </p>
              <ul class="role-features-list">
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Instant access to Permanent QR Pass (Works offline)</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Real-time waiting list queue & promotion alerts</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Complete personal event attendance history</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Instant self-service QR revocation & reissue</span>
                </li>
              </ul>
            </div>
            <div class="role-mockup-window">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; border-bottom: 1px solid var(--border-subtle); padding-bottom: 10px;">
                <span style="font-weight: 700; font-size: 0.95rem; color: var(--accent-white);">My Registered Events</span>
                <span style="font-size: 0.75rem; color: var(--status-green); background: var(--status-green-bg); padding: 3px 8px; border-radius: 99px;">3 Active</span>
              </div>
              <div style="background: rgba(255,255,255,0.03); border: 1px solid var(--border-subtle); border-radius: var(--radius-sm); padding: 12px; margin-bottom: 10px;">
                <div style="font-size: 0.85rem; font-weight: 700; color: var(--accent-white);">College Orientation 2026</div>
                <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">Today • 09:00 AM • University Hall</div>
                <div style="font-size: 0.75rem; color: var(--status-blue); margin-top: 6px;">● Status: Registered</div>
              </div>
              <div style="background: rgba(255,255,255,0.03); border: 1px solid var(--border-subtle); border-radius: var(--radius-sm); padding: 12px;">
                <div style="font-size: 0.85rem; font-weight: 700; color: var(--accent-white);">AI & Data Science Workshop</div>
                <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">Nov 20, 2026 • 01:00 PM • Room 402</div>
                <div style="font-size: 0.75rem; color: var(--status-amber); margin-top: 6px;">● Waiting List #2</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Organizer Tab Panel -->
        <div class="preview-role-panel" id="role-panel-organizer">
          <div class="role-showcase-box">
            <div class="role-details">
              <h3>Event Organizer & Staff Tools</h3>
              <p>
                Equips event coordinators with high-speed camera scanning, live headcounts, walk-in registration handling, and auditable manual corrections.
              </p>
              <ul class="role-features-list">
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Camera viewport with sub-second QR recognition</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Audio & visual confirmation on check-in / check-out</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Automatic late grace period detection (default 15m)</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Manual corrections requiring mandatory audit reason</span>
                </li>
              </ul>
            </div>
            <div class="role-mockup-window">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
                <span style="font-weight: 700; font-size: 0.95rem; color: var(--accent-white);">QR Scanner Viewfinder</span>
                <span style="font-size: 0.75rem; color: var(--status-green); font-family: var(--font-mono);">ACTIVE</span>
              </div>
              <div style="height: 140px; border: 2px dashed rgba(255,255,255,0.2); border-radius: var(--radius-sm); display: flex; align-items: center; justify-content: center; flex-direction: column; gap: 8px;">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--status-green)" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                <span style="font-size: 0.8rem; font-weight: 600; color: var(--accent-white);">Check-in Verified: Juan Dela Cruz</span>
                <span style="font-size: 0.7rem; color: var(--status-green);">Present • Timestamp: 08:12:44 AM</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Admin Tab Panel -->
        <div class="preview-role-panel" id="role-panel-admin">
          <div class="role-showcase-box">
            <div class="role-details">
              <h3>Administrator Governance</h3>
              <p>
                Full administrative oversight over institutional accounts, event publication approvals, cancellation reviews, broadcast announcements, and activity logs.
              </p>
              <ul class="role-features-list">
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Review & approve organizer event requests</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Inspect student QR histories & administrative reissue</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Broadcast announcements with FCM chime alerts</span>
                </li>
                <li>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                  <span>Tamper-proof system activity & security audit logs</span>
                </li>
              </ul>
            </div>
            <div class="role-mockup-window">
              <div style="font-weight: 700; font-size: 0.95rem; color: var(--accent-white); margin-bottom: 12px;">Recent Audit Activity</div>
              <div style="font-size: 0.75rem; font-family: var(--font-mono); color: var(--text-secondary); display: flex; flex-direction: column; gap: 8px;">
                <div style="background: rgba(255,255,255,0.02); padding: 8px; border-radius: 4px;">
                  <span style="color: var(--status-green);">[APPROVAL]</span> Event #12 approved by Admin
                </div>
                <div style="background: rgba(255,255,255,0.02); padding: 8px; border-radius: 4px;">
                  <span style="color: var(--status-blue);">[SCAN]</span> Check-in recorded for Student #20260001
                </div>
                <div style="background: rgba(255,255,255,0.02); padding: 8px; border-radius: 4px;">
                  <span style="color: var(--status-amber);">[PROMOTION]</span> Waiting list #1 auto-promoted to registered
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ── Download Section ──────────────────────────────────── -->
    <section class="section" id="download">
      <div class="container">
        <div class="download-wrapper">
          <div class="download-grid">
            <div class="download-content">
              <h2>Get Attendify for Android</h2>
              <p>
                Experience lightning-fast campus event check-in and check-out. Download the official Android APK directly to your phone, or open the Web App in any modern browser.
              </p>

              <div class="download-actions">
                <a href="{{ url('/download/apk') }}" download="attendify-release.apk" class="btn btn-primary btn-lg" id="downloadApkBtn" title="Download Attendify APK">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                  <span>Download Attendify APK</span>
                </a>

                <a href="{{ url('/app') }}" class="btn btn-secondary btn-lg">
                  <span>Launch Web App</span>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                </a>
              </div>

              <div class="download-meta">
                <span>Version 1.1</span>
                <span>•</span>
                <span>Android 8.0+</span>
                <span>•</span>
                <span>Production API: Render Cloud</span>
              </div>

              <!-- Android Install Guide -->
              <div class="install-guide-box">
                <div class="install-guide-title">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
                  <span>How to Install on Android</span>
                </div>
                <ul class="install-guide-steps">
                  <li>
                    <span class="install-step-num">1.</span>
                    <span>Tap <strong>Download Attendify APK</strong> above.</span>
                  </li>
                  <li>
                    <span class="install-step-num">2.</span>
                    <span>If prompted with <em>"File might be harmful"</em>, tap <strong>Download anyway</strong> (standard for non-Play Store APKs).</span>
                  </li>
                  <li>
                    <span class="install-step-num">3.</span>
                    <span>Open the downloaded file and toggle <strong>"Allow from this source"</strong> in Android Settings.</span>
                  </li>
                  <li>
                    <span class="install-step-num">4.</span>
                    <span>Launch Attendify and log in using your official <strong>Student ID Number</strong>!</span>
                  </li>
                </ul>
              </div>
            </div>

            <!-- QR Code Download Panel -->
            <div class="qr-download-panel">
              <div class="qr-box">
                <!-- SVG QR Code pointing directly to download URL -->
                <svg viewBox="0 0 100 100" fill="currentColor">
                  <rect x="0" y="0" width="28" height="28" rx="4" fill="#000"/>
                  <rect x="4" y="4" width="20" height="20" rx="2" fill="#fff"/>
                  <rect x="8" y="8" width="12" height="12" rx="1" fill="#000"/>

                  <rect x="72" y="0" width="28" height="28" rx="4" fill="#000"/>
                  <rect x="76" y="4" width="20" height="20" rx="2" fill="#fff"/>
                  <rect x="80" y="8" width="12" height="12" rx="1" fill="#000"/>

                  <rect x="0" y="72" width="28" height="28" rx="4" fill="#000"/>
                  <rect x="4" y="76" width="20" height="20" rx="2" fill="#fff"/>
                  <rect x="8" y="80" width="12" height="12" rx="1" fill="#000"/>

                  <!-- QR modules -->
                  <rect x="36" y="8" width="8" height="8" fill="#000"/>
                  <rect x="52" y="8" width="8" height="8" fill="#000"/>
                  <rect x="36" y="24" width="8" height="8" fill="#000"/>
                  <rect x="48" y="24" width="8" height="8" fill="#000"/>
                  <rect x="8" y="36" width="8" height="8" fill="#000"/>
                  <rect x="20" y="48" width="8" height="8" fill="#000"/>
                  <rect x="36" y="40" width="8" height="8" fill="#000"/>
                  <rect x="48" y="40" width="8" height="8" fill="#000"/>
                  <rect x="60" y="40" width="8" height="8" fill="#000"/>
                  <rect x="76" y="36" width="8" height="8" fill="#000"/>
                  <rect x="84" y="48" width="8" height="8" fill="#000"/>
                  <rect x="36" y="60" width="8" height="8" fill="#000"/>
                  <rect x="48" y="60" width="8" height="8" fill="#000"/>
                  <rect x="60" y="60" width="8" height="8" fill="#000"/>
                  <rect x="36" y="76" width="8" height="8" fill="#000"/>
                  <rect x="52" y="76" width="8" height="8" fill="#000"/>
                  <rect x="72" y="72" width="12" height="12" fill="#000"/>
                  <rect x="84" y="84" width="12" height="12" fill="#000"/>
                </svg>
              </div>
              <div class="qr-download-label">Scan on Phone to Download</div>
              <div class="qr-download-sub">Point your camera to download the APK directly</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </main>

  <!-- ── Footer ────────────────────────────────────────────── -->
  <footer class="footer" role="contentinfo">
    <div class="container">
      <div class="footer-grid">
        <div class="footer-brand">
          <div class="footer-brand-title">
            <img src="{{ asset('images/logo_icon.svg') }}" alt="Attendify Mark" width="28" height="28" onerror="this.src='{{ asset('images/logo_mark.png') }}'">
            <span>Attendify</span>
          </div>
          <p class="footer-brand-desc">
            School Event Registration and QR-Based Attendance Management System. Providing seamless, auditable event governance for educational institutions.
          </p>
        </div>

        <div class="footer-col">
          <h4>Navigation</h4>
          <ul class="footer-links">
            <li><a href="#home" class="footer-link">Home</a></li>
            <li><a href="#about" class="footer-link">About Attendify</a></li>
            <li><a href="#features" class="footer-link">Features</a></li>
            <li><a href="#how-it-works" class="footer-link">How It Works</a></li>
            <li><a href="#download" class="footer-link">Download APK</a></li>
          </ul>
        </div>

        <div class="footer-col">
          <h4>Platform</h4>
          <ul class="footer-links">
            <li><a href="{{ url('/app') }}" class="footer-link">Web App Portal</a></li>
            <li><a href="https://github.com/jover188/School-Event-Registration-and-QR-Based-Attendance" class="footer-link" target="_blank" rel="noopener noreferrer">GitHub Repository</a></li>
            <li><a href="https://attendify-fugh.onrender.com/api/v1/events" class="footer-link" target="_blank" rel="noopener noreferrer">REST API v1</a></li>
            <li><a href="#download" class="footer-link">Android Release</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <div>&copy; {{ date('Y') }} Attendify. All rights reserved.</div>
        <div>Minimalist Institutional Edition • Built with Laravel & Flutter</div>
      </div>
    </div>
  </footer>

  <!-- Vanilla JavaScript -->
  <script src="{{ asset('js/landing.js') }}"></script>
</body>
</html>
