"""
main.py - Master compiler for Attendify Frontend Developer Guide.
Assembles all 22 chapters plus glossary, applies executive styling, saves .docx, and compiles .pdf.
"""

import os
import sys
import time
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

from .styles import (
    setup_document_styles, setup_headers_and_footers, add_cover_page,
    add_chapter_title, add_section_title, add_body_p, add_bullet_item,
    add_callout, add_styled_table, HEX_PRIMARY, COLOR_PRIMARY, COLOR_ACCENT, FONT_PRIMARY
)
from .part1 import add_part1
from .part2 import add_part2
from .part3 import add_part3
from .part4 import add_part4
from .part5 import add_part5

def add_revision_history(doc):
    """Add document control and revision history."""
    p_rh = doc.add_paragraph()
    p_rh.paragraph_format.space_before = Pt(14)
    p_rh.paragraph_format.space_after = Pt(4)
    r_rh = p_rh.add_run("Document Control & Revision History")
    r_rh.font.name = FONT_PRIMARY
    r_rh.font.size = Pt(14.0)
    r_rh.font.bold = True
    r_rh.font.color.rgb = COLOR_PRIMARY

    rh_headers = ["Revision", "Release Date", "Author / Role", "Summary of Technical Changes"]
    rh_rows = [
        ["v1.0.0", "November 2026", "Lead Mobile Architect", "Initial baseline architecture, 20-screen UI inventory, ApiClient REST integration."],
        ["v1.1.0", "November 2026", "Frontend Engineering Team", "Dual Light/Dark/System Default theme system, header toggle, AppThemeController, 202 passing tests."]
    ]
    add_styled_table(doc, rh_headers, rh_rows, col_widths=[1.0, 1.3, 1.8, 2.4])

def add_table_of_contents(doc):
    """Add a structured, comprehensive Table of Contents overview."""
    p_toc = doc.add_paragraph()
    p_toc.paragraph_format.space_before = Pt(14)
    p_toc.paragraph_format.space_after = Pt(6)
    r_toc = p_toc.add_run("Table of Contents & Chapter Index")
    r_toc.font.name = FONT_PRIMARY
    r_toc.font.size = Pt(16.0)
    r_toc.font.bold = True
    r_toc.font.color.rgb = COLOR_PRIMARY

    add_body_p(doc, "This technical reference manual provides complete architectural, styling, and implementation instructions for developers building and maintaining the Attendify Flutter application (`mobile/`):")

    toc_headers = ["Chapter", "Chapter Title", "Core Technical Focus"]
    toc_rows = [
        ["Chapter 1", "Frontend Project Overview", "Platform responsibilities, decoupled REST model, supported environments."],
        ["Chapter 2", "Development Environment Setup", "Flutter/Dart SDK setup, IDE plugins, local run commands, build pipelines."],
        ["Chapter 3", "Frontend Architecture", "Layered client architecture, entrypoint lifecycle, system interaction diagram."],
        ["Chapter 4", "Complete Frontend Folder Structure", "Directory taxonomy across core/, models/, screens/, and shared utilities."],
        ["Chapter 5", "Application Navigation", "Initial route resolver, AppShell adaptive scaffolding, navigation flow diagram."],
        ["Chapter 6", "Complete Screen Inventory", "In-depth technical catalog of all 21 production screens in mobile/lib/screens/."],
        ["Chapter 7", "UI Components & Reusable Widgets", "Central widget library (AppButton, AppShell, EventCard, StatusBadge) and usage."],
        ["Chapter 8", "AetherUI Design System", "Light/Dark token palettes, Inter typography scale, spacing grid, WCAG AA compliance."],
        ["Chapter 9", "State Management & Reactivity", "StatefulWidgets, ValueNotifier, ChangeNotifier, AppThemeController, state diagram."],
        ["Chapter 10", "REST API Integration", "ApiClient implementation, emulator auto-fallback, Bearer headers, endpoint matrix."],
        ["Chapter 11", "Authentication & Single-Session", "Login flow, token storage, single active session termination dialog, 4 roles."],
        ["Chapter 12", "Event Management Frontend", "Event form, audience targeting options, capacity metering, FIFO queue feedback."],
        ["Chapter 13", "Calendar & QR Attendance Scanning", "TableCalendar integration, MobileScanner hardware camera, grace period logic."],
        ["Chapter 14", "Notifications & FCM", "PushNotificationService (FCM), foreground chimes, unread counts, tap routing."],
        ["Chapter 15", "Forms & Input Validation", "TextControllers, regex validators, required fields, backend 422 error mapping."],
        ["Chapter 16", "Responsive Design & Cross-Platform", "ResponsiveLayout breakpoints, mobile bottom nav vs desktop sidebar, web vs APK."],
        ["Chapter 17", "Error Handling & Debugging", "ApiResponse envelope, AppToast, DevTools, Android logcat runbook."],
        ["Chapter 18", "Frontend Testing", "AppTestHost harness, 202 automated passing tests, test inventory breakdown."],
        ["Chapter 19", "Coding Standards & Guidelines", "Zero hardcoded colors, single responsibility, lifecycle disposal, clean code."],
        ["Chapter 20", "Frontend Development Workflow", "10-step feature development runbook from requirement to automated test."],
        ["Chapter 21", "Known Issues & Pending Work", "Operational constraints (Render cold start, battery savers) and v2.0 roadmap."],
        ["Chapter 22", "Frontend Developer Quick Reference", "Everyday Flutter & ADB command cheat sheet and essential file paths."],
        ["Chapter 23", "Glossary of Technical Terms", "Definitions and operational context for core frontend engineering terms."]
    ]
    add_styled_table(doc, toc_headers, toc_rows, col_widths=[1.1, 2.3, 3.1])
    doc.add_page_break()

def generate_fe_guide():
    print("=" * 70)
    print("ATTENDIFY FRONTEND DEVELOPER GUIDE GENERATION")
    print("=" * 70)
    start_time = time.time()

    doc = docx.Document()
    setup_document_styles(doc)
    setup_headers_and_footers(doc)

    print("[1/7] Adding Executive Cover Page...")
    add_cover_page(doc)

    print("[2/7] Adding Revision History & Executive Table of Contents...")
    add_revision_history(doc)
    add_table_of_contents(doc)

    print("[3/7] Generating Part 1 (Chapters 1 to 5)...")
    add_part1(doc)

    print("[4/7] Generating Part 2 (Chapters 6 to 8)...")
    add_part2(doc)

    print("[5/7] Generating Part 3 (Chapters 9 to 13)...")
    add_part3(doc)

    print("[6/7] Generating Part 4 (Chapters 14 to 18)...")
    add_part4(doc)

    print("[7/7] Generating Part 5 (Chapters 19 to 23)...")
    add_part5(doc)

    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "documentation"))
    os.makedirs(out_dir, exist_ok=True)
    docx_path = os.path.join(out_dir, "Attendify_Frontend_Developer_Guide.docx")
    pdf_path = os.path.join(out_dir, "Attendify_Frontend_Developer_Guide.pdf")

    print(f"Saving DOCX to: {docx_path}")
    doc.save(docx_path)
    docx_size_kb = os.path.getsize(docx_path) / 1024
    print(f"DOCX successfully generated! Size: {docx_size_kb:.1f} KB")
    print(f"Total Paragraphs: {len(doc.paragraphs)}, Total Tables: {len(doc.tables)}")

    print("-" * 70)
    print("Compiling PDF via docx2pdf...")
    pdf_generated = False
    try:
        from docx2pdf import convert
        convert(docx_path, pdf_path)
        if os.path.exists(pdf_path):
            pdf_size_kb = os.path.getsize(pdf_path) / 1024
            print(f"PDF successfully compiled! Size: {pdf_size_kb:.1f} KB")
            pdf_generated = True
        else:
            print("Warning: PDF file was not created by docx2pdf.")
    except Exception as e:
        print(f"Note: PDF generation encountered an exception: {e}")
        print("DOCX remains available as the primary deliverable.")

    elapsed = time.time() - start_time
    print("=" * 70)
    print(f"GENERATION COMPLETE in {elapsed:.2f} seconds.")
    print(f"DOCX: {docx_path} ({docx_size_kb:.1f} KB)")
    if pdf_generated:
        print(f"PDF:  {pdf_path} ({pdf_size_kb:.1f} KB)")
    print("=" * 70)

if __name__ == "__main__":
    generate_fe_guide()
