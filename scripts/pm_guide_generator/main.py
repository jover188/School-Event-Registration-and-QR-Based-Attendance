"""
main.py - Master compiler for Attendify Project Manager Guide.
Assembles all chapters, applies executive styling, saves .docx, and compiles .pdf.
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

def add_table_of_contents(doc):
    """Add a structured, executive Table of Contents overview."""
    p_toc = doc.add_paragraph()
    p_toc.paragraph_format.space_before = Pt(14)
    p_toc.paragraph_format.space_after = Pt(6)
    r_toc = p_toc.add_run("Table of Contents & Chapter Index")
    r_toc.font.name = FONT_PRIMARY
    r_toc.font.size = Pt(16.0)
    r_toc.font.bold = True
    r_toc.font.color.rgb = COLOR_PRIMARY

    add_body_p(doc, "This operational guide is structured into 18 comprehensive chapters designed to provide the Project Manager, Steering Committee, and Technical Leads with a complete governance, deliverable tracking, risk mitigation, and handover framework:")

    toc_headers = ["Chapter", "Chapter Title", "Core Focus & Governance Scope"]
    toc_rows = [
        ["Chapter 1", "Project Overview", "Problem statement, institutional objectives, scope boundaries, target user groups."],
        ["Chapter 2", "Project Description", "Architectural mechanism, decoupled client-server model, web/mobile overview."],
        ["Chapter 3", "Project Stakeholders", "Stakeholder profiles, governance responsibilities, RACI matrix."],
        ["Chapter 4", "Project Scope & Deliverables", "Deliverables status matrix across Backend, Mobile, DB, Docs, QA, Deployment."],
        ["Chapter 5", "System Modules & Features", "Managerial specifications across all 13 major functional subsystems."],
        ["Chapter 6", "Project Timeline & Milestones", "Agile Sprints 1–6 breakdown, historical completion, TBD future rollout."],
        ["Chapter 7", "Task & Responsibility Governance", "Work breakdown structure, task inventory, dependencies, acceptance criteria."],
        ["Chapter 8", "Project Progress Monitoring", "Progress monitoring procedures, core KPIs, Project Status Report template."],
        ["Chapter 9", "Risk Management & Mitigation", "Risk governance model, 8-factor risk register matrix, mitigation plans."],
        ["Chapter 10", "Issue & Defect Management", "Triage framework, severity vs priority matrix, Bug Report template."],
        ["Chapter 11", "Quality Assurance & Testing", "Multi-tier testing pyramid, 319 automated tests evidence, module criteria."],
        ["Chapter 12", "Deployment & Release Management", "Render cloud hosting, GitHub Actions APK CI/CD, versioning, rollback."],
        ["Chapter 13", "Communication & Team Coordination", "Cadence, escalation paths, Weekly Progress Meeting Minutes template."],
        ["Chapter 14", "Change Management", "Formal change control workflow, impact assessment, Change Request template."],
        ["Chapter 15", "Project Performance Evaluation", "Evaluation metrics, test pass rates, Project Manager final performance verdict."],
        ["Chapter 16", "Project Handover & Maintenance", "Handover checklist, documentation catalog, post-launch maintenance roadmap."],
        ["Chapter 17", "Known Issues & Pending Work", "Operational constraints (Render spin-down, FCM), future roadmap features."],
        ["Chapter 18", "Project Manager Reference Templates", "Complete library of 9 ready-to-use executive templates for PM operations."]
    ]
    add_styled_table(doc, toc_headers, toc_rows, col_widths=[1.1, 2.2, 3.2])
    doc.add_page_break()

def generate_pm_guide():
    print("=" * 70)
    print("ATTENDIFY PROJECT MANAGER GUIDE GENERATION")
    print("=" * 70)
    start_time = time.time()

    doc = docx.Document()
    setup_document_styles(doc)
    setup_headers_and_footers(doc)

    print("[1/6] Adding Executive Cover Page...")
    add_cover_page(doc)

    print("[2/6] Adding Executive Table of Contents...")
    add_table_of_contents(doc)

    print("[3/6] Generating Part 1 (Chapters 1 to 5)...")
    add_part1(doc)

    print("[4/6] Generating Part 2 (Chapters 6 to 10)...")
    add_part2(doc)

    print("[5/6] Generating Part 3 (Chapters 11 to 15)...")
    add_part3(doc)

    print("[6/6] Generating Part 4 (Chapters 16 to 18)...")
    add_part4(doc)

    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "documentation"))
    os.makedirs(out_dir, exist_ok=True)
    docx_path = os.path.join(out_dir, "Attendify_Project_Manager_Guide.docx")
    pdf_path = os.path.join(out_dir, "Attendify_Project_Manager_Guide.pdf")

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
    generate_pm_guide()
