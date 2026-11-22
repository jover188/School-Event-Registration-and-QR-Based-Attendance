"""
main.py - Main entry point to generate Attendify Complete System Analyst Documentation (.docx and .pdf).
"""

import os
import sys
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

from .styles import (
    setup_document_styles, setup_headers_and_footers, add_cover_page,
    set_table_borders, set_cell_background, set_cell_margins, add_styled_table,
    HEX_PRIMARY, HEX_SURFACE_ALT, HEX_ACCENT, COLOR_PRIMARY, COLOR_ACCENT,
    COLOR_TEXT_DARK, COLOR_TEXT_MUTED, FONT_PRIMARY
)
from .content_part1 import build_part1
from .content_part2 import build_part2
from .content_part3 import build_part3
from .content_part4 import build_part4

def add_table_of_contents_overview(doc):
    """Add a beautifully formatted executive Table of Contents."""
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(18)
    p_title.paragraph_format.space_after = Pt(8)
    r_title = p_title.add_run("Table of Contents")
    r_title.font.name = FONT_PRIMARY
    r_title.font.size = Pt(20)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_PRIMARY

    p_desc = doc.add_paragraph()
    r_desc = p_desc.add_run("This document contains 33 comprehensive chapters organized into 5 major analytical divisions:")
    r_desc.font.name = FONT_PRIMARY
    r_desc.font.size = Pt(10)
    r_desc.font.color.rgb = COLOR_TEXT_MUTED
    p_desc.paragraph_format.space_after = Pt(12)

    toc_headers = ["Chapter #", "Chapter Title", "Major Analytical Scope"]
    toc_rows = [
        ["Chapter 1", "Document Information & Revision History", "Metadata, Target Audience, Release Milestones (v1.0 to v1.1)"],
        ["Chapter 2", "Executive Summary", "Strategic Rationale, Core Invariants, High-Level Innovations"],
        ["Chapter 3", "Introduction and Background", "Campus Operational Context, Legacy Paper Failures, Evolution"],
        ["Chapter 4", "System Purpose, Objectives, and Scope", "Functional In-Scope Capabilities vs Out-of-Scope Boundaries"],
        ["Chapter 5", "System Architecture & Technology Stack", "Decoupled Architecture Diagram, Frameworks & Tooling"],
        ["Chapter 6", "System Requirements & Dependencies", "Server Hardware, Client OS, PHP Extensions, Network Ports"],
        ["Chapter 7", "User Roles and Access Permissions", "4 Immutable Roles, Granular CRUD Role-Permission Matrix"],
        ["Chapter 8", "Authentication & Account Management", "Student ID/Email Login, Sanctum Tokens, Single-Session UUID"],
        ["Chapter 9", "Student Profile Management", "Institutional Record Immutability, Discrepancy Ticket Workflow"],
        ["Chapter 10", "Event Management & Lifecycle Governance", "Finite State Machine (Draft -> Published -> Completed/Cancelled)"],
        ["Chapter 11", "Event Audience Targeting & Assignment", "Department/Course/Year Cohort Rules, Automated Broadcasts"],
        ["Chapter 12", "Event Calendar and Role Dashboards", "Calendar Grid, Category Filtering, Role-Specific Aggregations"],
        ["Chapter 13", "Permanent QR Code Management", "64-Char Hex Cryptographic Token, Zero PII, Reissue Workflow"],
        ["Chapter 14", "QR-Based Attendance Management", "attendances Schema, Status Enums, Scanner Accountability"],
        ["Chapter 15", "Check-In and Check-Out Workflows", "Scanner Rate Limits, Late Grace Period, Walk-In Admission"],
        ["Chapter 16", "Participation Verification & Corrections", "Post-Event Audit, Mandatory Justification, Relational History"],
        ["Chapter 17", "Notification & Announcement Management", "User Preferences, Mandatory Alerts, 30-Day Automated Purge"],
        ["Chapter 18", "Firebase Cloud Messaging (FCM) Push", "HTTP v1 Google OAuth, Device Token Pool, Sound Chimes"],
        ["Chapter 19", "In-App Notification Inbox", "Realtime Polling Daemon, Unread Badge, Direct Event Routing"],
        ["Chapter 20", "Reports and Data Export", "7 Institutional Reports, PDF/XLSX/CSV Engines, FileDownloader"],
        ["Chapter 21", "Activity Logs and Audit Trail", "Immutable Relational Logging, Audited Operational Events"],
        ["Chapter 22", "Database Structure and Relationships", "13 Domain Tables, Data Types, Constraints, Textual ERD"],
        ["Chapter 23", "REST API Architecture & Endpoints", "JSON Response Envelopes, Complete 47-Endpoint Route Catalog"],
        ["Chapter 24", "Frontend and Backend Communication", "ApiClient Singleton, Bearer Injection, 401 Session Interceptor"],
        ["Chapter 25", "Complete System Workflows", "End-to-End Sequence Walkthroughs (Provisioning, Event, Scan)"],
        ["Chapter 26", "Security and Authorization Architecture", "Defense-in-Depth, Rate Limiting, SQL Injection & XSS Guard"],
        ["Chapter 27", "Deployment & Hosting Architecture", "Render PaaS Containerization, Unified Origin, Base Href SPA"],
        ["Chapter 28", "Configuration & Environment Variables", "Laravel .env Catalog, Secret Management, Flutter Defines"],
        ["Chapter 29", "Testing Procedures and Test Cases", "117 Backend Tests (SQLite :memory:), 202 Flutter Mobile Tests"],
        ["Chapter 30", "Known Limitations & Boundaries", "Online Scanning Dependency, No Public Self-Registration, No AI"],
        ["Chapter 31", "Troubleshooting Guide & Runbook", "Diagnostic Tree for Common Errors (Sessions, Scans, Base Href)"],
        ["Chapter 32", "Glossary of Technical Terms", "Definitions for 40+ Technical and Domain Concepts"],
        ["Chapter 33", "Appendix and Supporting References", "Repository File Map, Canonical Specifications, Milestone Log"]
    ]

    add_styled_table(doc, toc_headers, toc_rows, [1.1, 2.5, 2.9])
    doc.add_page_break()

def generate_documentation():
    print("Initializing Attendify System Analyst Documentation Generator...")
    doc = docx.Document()

    # Step 1: Base Configuration
    setup_document_styles(doc)

    # Step 2: Cover Page
    print("Generating Cover Page...")
    add_cover_page(doc)

    # Step 3: Table of Contents
    print("Generating Table of Contents...")
    add_table_of_contents_overview(doc)

    # Step 4: Headers & Footers
    setup_headers_and_footers(doc)

    # Step 5: Content Chapters
    print("Building Chapters 1 - 8 (Part 1: Overview, Architecture, Roles, Auth)...")
    build_part1(doc)

    print("Building Chapters 9 - 16 (Part 2: Profiles, Events, QR, Attendance, Scans)...")
    build_part2(doc)

    print("Building Chapters 17 - 24 (Part 3: Notifications, FCM, Reports, Logs, Database, APIs)...")
    build_part3(doc)

    print("Building Chapters 25 - 33 (Part 4: Workflows, Security, Deploy, Test, Runbook, Glossary)...")
    build_part4(doc)

    # Step 6: Save Document
    output_dir = os.path.join(os.getcwd(), "documentation")
    os.makedirs(output_dir, exist_ok=True)
    docx_path = os.path.join(output_dir, "Attendify_Complete_System_Analyst_Documentation.docx")
    pdf_path = os.path.join(output_dir, "Attendify_Complete_System_Analyst_Documentation.pdf")

    print(f"Saving DOCX to: {docx_path}")
    doc.save(docx_path)
    print("DOCX successfully generated and saved!")

    # Step 7: Export to PDF
    print("Attempting PDF export via docx2pdf...")
    try:
        from docx2pdf import convert
        convert(docx_path, pdf_path)
        print(f"PDF successfully generated at: {pdf_path}")
    except Exception as e:
        print(f"Note: docx2pdf export encountered: {e}")
        print("DOCX file is fully intact and ready in documentation/ directory.")

if __name__ == "__main__":
    generate_documentation()
