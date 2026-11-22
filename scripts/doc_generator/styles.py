"""
styles.py - Document styling and layout primitives for Attendify System Analyst Documentation.
"""

import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

# Core Color Palette (Attendify Black & White + Emerald/Teal Accent)
HEX_PRIMARY = "18181B"      # Dark Charcoal / Black
HEX_ACCENT = "0D9488"       # Teal Accent
HEX_SECONDARY = "27272A"    # Secondary Dark
HEX_TEXT_DARK = "09090B"    # Main Body Text
HEX_TEXT_MUTED = "52525B"   # Supporting / Muted
HEX_BORDER = "E4E4E7"       # Subtle Border
HEX_SURFACE = "FAFAFA"      # Background Surface
HEX_SURFACE_ALT = "F4F4F5"  # Card / Table Header Alt
HEX_CALLOUT_BORDER = "0D9488"

COLOR_PRIMARY = RGBColor(24, 24, 27)
COLOR_ACCENT = RGBColor(13, 148, 136)
COLOR_TEXT_DARK = RGBColor(9, 9, 11)
COLOR_TEXT_MUTED = RGBColor(82, 82, 91)
COLOR_WHITE = RGBColor(255, 255, 255)

FONT_PRIMARY = "Segoe UI"
FONT_CODE = "Consolas"

def set_cell_background(cell, fill_hex):
    """Set background color of a table cell."""
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), fill_hex)
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    """Set inner padding for a table cell in dxa (1 pt = 20 dxa)."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_table_borders(table, color=HEX_BORDER, sz="4", val="single"):
    """Set custom borders for modern minimalist table appearance."""
    tblPr = table._tbl.tblPr
    tblBorders = OxmlElement('w:tblBorders')
    for b_name in ['top', 'bottom', 'left', 'right', 'insideH']:
        border = OxmlElement(f'w:{b_name}')
        border.set(qn('w:val'), val)
        border.set(qn('w:sz'), sz)
        border.set(qn('w:space'), '0')
        border.set(qn('w:color'), color)
        tblBorders.append(border)
    border_v = OxmlElement('w:insideV')
    border_v.set(qn('w:val'), 'none')
    tblBorders.append(border_v)
    tblPr.append(tblBorders)

def setup_document_styles(doc):
    """Configure default margins, standard styles, and base typography."""
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.page_width = Inches(8.5)
        section.page_height = Inches(11.0)

    # Configure Normal style
    style_normal = doc.styles['Normal']
    font = style_normal.font
    font.name = FONT_PRIMARY
    font.size = Pt(10.5)
    font.color.rgb = COLOR_TEXT_DARK
    style_normal.paragraph_format.line_spacing = 1.25
    style_normal.paragraph_format.space_after = Pt(4)
    style_normal.paragraph_format.space_before = Pt(0)

def setup_headers_and_footers(doc):
    """Configure running header and footer with page numbering on subsequent sections."""
    for section in doc.sections:
        # Header
        header = section.header
        header.is_linked_to_previous = False
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Attendify – Complete System Analyst Documentation  |  v1.1")
        hrun.font.name = FONT_PRIMARY
        hrun.font.size = Pt(8.5)
        hrun.font.color.rgb = COLOR_TEXT_MUTED

        # Footer
        footer = section.footer
        footer.is_linked_to_previous = False
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.LEFT
        frun = fp.add_run("CONFIDENTIAL & PROPRIETARY  —  FOR AUTHORIZED SYSTEM ANALYSTS & AUDITORS ONLY")
        frun.font.name = FONT_PRIMARY
        frun.font.size = Pt(8.0)
        frun.font.color.rgb = COLOR_TEXT_MUTED

def add_cover_page(doc):
    """Add a corporate, high-impact cover page for System Analysts."""
    # Top spacing
    p_top = doc.add_paragraph()
    p_top.paragraph_format.space_before = Pt(40)
    p_top.paragraph_format.space_after = Pt(8)

    # Super title / Institutional tag
    p_tag = doc.add_paragraph()
    r_tag = p_tag.add_run("INSTITUTIONAL TECHNICAL SPECIFICATION & FUNCTIONAL REFERENCE")
    r_tag.font.name = FONT_PRIMARY
    r_tag.font.size = Pt(10.5)
    r_tag.font.bold = True
    r_tag.font.color.rgb = COLOR_ACCENT
    p_tag.paragraph_format.space_after = Pt(14)

    # Main Title
    p_title = doc.add_paragraph()
    r_title = p_title.add_run("ATTENDIFY")
    r_title.font.name = FONT_PRIMARY
    r_title.font.size = Pt(36)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_PRIMARY
    p_title.paragraph_format.space_after = Pt(4)

    # Subtitle
    p_sub = doc.add_paragraph()
    r_sub = p_sub.add_run("School Event Registration and QR-Based Attendance Management System")
    r_sub.font.name = FONT_PRIMARY
    r_sub.font.size = Pt(16)
    r_sub.font.bold = True
    r_sub.font.color.rgb = COLOR_TEXT_MUTED
    p_sub.paragraph_format.space_after = Pt(16)

    # Manual Tagline
    p_desc = doc.add_paragraph()
    r_desc = p_desc.add_run("Comprehensive System Analyst Technical Reference Guide, Architecture Blueprint, Database Schema, Workflows, Security Policies, and Operational Runbook")
    r_desc.font.name = FONT_PRIMARY
    r_desc.font.size = Pt(12)
    r_desc.font.color.rgb = COLOR_TEXT_DARK
    p_desc.paragraph_format.space_after = Pt(30)

    # Decorative Line / Divider
    p_div = doc.add_paragraph()
    r_div = p_div.add_run("―" * 52)
    r_div.font.color.rgb = COLOR_ACCENT
    r_div.font.bold = True
    p_div.paragraph_format.space_after = Pt(30)

    # Metadata Summary Box / Table
    meta_table = doc.add_table(rows=6, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(meta_table, color="D4D4D8", sz="6", val="single")

    meta_rows = [
        ("Target Audience:", "System Analysts, Solutions Architects, Tech Leads, QA Engineers"),
        ("System Version:", "Release 1.1.0 (Production Stable Baseline)"),
        ("Backend Stack:", "Laravel 11 REST API / PHP 8.2+ / MySQL 8.0+ / MariaDB"),
        ("Frontend Stack:", "Flutter 3.47+ / Dart 3.13+ (Android APK & Flutter Web)"),
        ("Date of Publication:", "November 22, 2026"),
        ("Document Classification:", "Confidential — Institutional Operations Reference (v1.1)"),
    ]

    for i, (label, val) in enumerate(meta_rows):
        row = meta_table.rows[i]
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(2.2)
        c1.width = Inches(4.3)
        set_cell_background(c0, HEX_SURFACE_ALT)
        set_cell_background(c1, "FFFFFF")
        set_cell_margins(c0, top=100, bottom=100, left=140, right=140)
        set_cell_margins(c1, top=100, bottom=100, left=140, right=140)

        p0 = c0.paragraphs[0]
        r0 = p0.add_run(label)
        r0.font.bold = True
        r0.font.size = Pt(9.5)
        r0.font.color.rgb = COLOR_PRIMARY

        p1 = c1.paragraphs[0]
        r1 = p1.add_run(val)
        r1.font.size = Pt(9.5)
        r1.font.color.rgb = COLOR_TEXT_DARK

    p_bottom = doc.add_paragraph()
    p_bottom.paragraph_format.space_before = Pt(40)
    doc.add_page_break()

def add_chapter_title(doc, chapter_num, title):
    """Add a Level 1 Chapter Title with clear visual separation."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(22)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.keep_with_next = True

    r_num = p.add_run(f"CHAPTER {chapter_num}\n")
    r_num.font.name = FONT_PRIMARY
    r_num.font.size = Pt(10.0)
    r_num.font.bold = True
    r_num.font.color.rgb = COLOR_ACCENT

    r_title = p.add_run(title)
    r_title.font.name = FONT_PRIMARY
    r_title.font.size = Pt(18.0)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_PRIMARY

def add_section_title(doc, section_label, title):
    """Add a Level 2 Section Title."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True

    r = p.add_run(f"{section_label} {title}")
    r.font.name = FONT_PRIMARY
    r.font.size = Pt(13.0)
    r.font.bold = True
    r.font.color.rgb = COLOR_PRIMARY

def add_subsection_title(doc, subsection_label, title):
    """Add a Level 3 Subsection Title."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True

    r = p.add_run(f"{subsection_label} {title}")
    r.font.name = FONT_PRIMARY
    r.font.size = Pt(11.0)
    r.font.bold = True
    r.font.color.rgb = COLOR_ACCENT

def add_body_p(doc, text, bold_prefix=None, italic_prefix=None):
    """Add standard body paragraph with optional bold/italic prefixes."""
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.25

    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_PRIMARY

    if italic_prefix:
        r_it = p.add_run(italic_prefix)
        r_it.font.italic = True
        r_it.font.color.rgb = COLOR_TEXT_MUTED

    r_text = p.add_run(text)
    r_text.font.size = Pt(10.0)
    r_text.font.color.rgb = COLOR_TEXT_DARK
    return p

def add_bullet_item(doc, text, bold_prefix=None, level=0):
    """Add bullet list item."""
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.left_indent = Inches(0.25 * (level + 1))
    p.paragraph_format.line_spacing = 1.2

    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_PRIMARY

    r_text = p.add_run(text)
    r_text.font.size = Pt(10.0)
    r_text.font.color.rgb = COLOR_TEXT_DARK
    return p

def add_callout(doc, text, title="IMPORTANT NOTICE", alert_type="note"):
    """Render a shaded callout container box with bold title and left border."""
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.cell(0, 0)
    cell.width = Inches(6.5)

    # Shading & border
    bg_color = "F0FDFA" if alert_type == "tip" else ("FEF2F2" if alert_type == "warning" else HEX_SURFACE_ALT)
    border_color = HEX_ACCENT if alert_type == "tip" else ("EF4444" if alert_type == "warning" else HEX_PRIMARY)

    set_cell_background(cell, bg_color)
    set_cell_margins(cell, top=140, bottom=140, left=180, right=180)

    # Left thick border, others none
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    left_b = OxmlElement('w:left')
    left_b.set(qn('w:val'), 'single')
    left_b.set(qn('w:sz'), '24') # 3pt thick border
    left_b.set(qn('w:space'), '0')
    left_b.set(qn('w:color'), border_color)
    tcBorders.append(left_b)

    for b in ['top', 'bottom', 'right']:
        b_node = OxmlElement(f'w:{b}')
        b_node.set(qn('w:val'), 'none')
        tcBorders.append(b_node)
    tcPr.append(tcBorders)

    cp = cell.paragraphs[0]
    cp.paragraph_format.space_after = Pt(2)
    rt = cp.add_run(f"[{title.upper()}]  ")
    rt.font.name = FONT_PRIMARY
    rt.font.size = Pt(9.5)
    rt.font.bold = True
    rt.font.color.rgb = COLOR_ACCENT if alert_type == "tip" else (RGBColor(239, 68, 68) if alert_type == "warning" else COLOR_PRIMARY)

    rc = cp.add_run(text)
    rc.font.name = FONT_PRIMARY
    rc.font.size = Pt(9.5)
    rc.font.color.rgb = COLOR_TEXT_DARK

    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_before = Pt(4)
    p_after.paragraph_format.space_after = Pt(4)

def add_styled_table(doc, headers, rows, col_widths=None):
    """Add a clean, publication-ready table with styled header and alternating rows."""
    table = doc.add_table(rows=len(rows) + 1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table, color=HEX_BORDER, sz="4", val="single")

    # Header Row
    hdr_row = table.rows[0]
    for i, h_text in enumerate(headers):
        cell = hdr_row.cells[i]
        set_cell_background(cell, HEX_PRIMARY)
        set_cell_margins(cell, top=120, bottom=120, left=140, right=140)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(h_text)
        r.font.name = FONT_PRIMARY
        r.font.bold = True
        r.font.size = Pt(9.5)
        r.font.color.rgb = COLOR_WHITE

    # Data Rows
    for r_idx, r_data in enumerate(rows):
        row = table.rows[r_idx + 1]
        bg_hex = "FFFFFF" if r_idx % 2 == 0 else HEX_SURFACE_ALT
        for c_idx, val in enumerate(r_data):
            cell = row.cells[c_idx]
            set_cell_background(cell, bg_hex)
            set_cell_margins(cell, top=90, bottom=90, left=140, right=140)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15
            r = p.add_run(str(val))
            r.font.name = FONT_PRIMARY
            r.font.size = Pt(9.0)
            r.font.color.rgb = COLOR_TEXT_DARK

    # Column Widths
    if col_widths and len(col_widths) == len(headers):
        for row in table.rows:
            for c_idx, w in enumerate(col_widths):
                row.cells[c_idx].width = Inches(w)

    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_after = Pt(6)
    return table

def add_code_block(doc, code_text):
    """Add a monospace formatted code / diagram container."""
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.cell(0, 0)
    cell.width = Inches(6.5)

    set_cell_background(cell, "F8FAFC")
    set_cell_margins(cell, top=120, bottom=120, left=140, right=140)
    set_table_borders(table, color="CBD5E1", sz="6", val="single")

    cp = cell.paragraphs[0]
    cp.paragraph_format.space_after = Pt(0)
    cp.paragraph_format.line_spacing = 1.1
    r = cp.add_run(code_text)
    r.font.name = FONT_CODE
    r.font.size = Pt(8.5)
    r.font.color.rgb = RGBColor(15, 23, 42)

    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_after = Pt(6)
