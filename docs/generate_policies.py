"""Generate sample HR policy PDF documents using ReportLab."""

import os
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle


STYLES = getSampleStyleSheet()
TITLE_STYLE = ParagraphStyle(
    "CustomTitle",
    parent=STYLES["Title"],
    fontSize=24,
    spaceAfter=20,
    textColor=HexColor("#1a365d"),
)
HEADING_STYLE = ParagraphStyle(
    "CustomHeading",
    parent=STYLES["Heading2"],
    fontSize=14,
    spaceBefore=16,
    spaceAfter=8,
    textColor=HexColor("#2563eb"),
)
BODY_STYLE = ParagraphStyle(
    "CustomBody",
    parent=STYLES["BodyText"],
    fontSize=11,
    spaceAfter=6,
    leading=16,
)


def build_pdf(filename, title, sections):
    """Build a PDF with a title and list of (heading, body_paragraphs) sections."""
    output_dir = os.path.join(os.path.dirname(__file__), "sample-policies")
    os.makedirs(output_dir, exist_ok=True)
    filepath = os.path.join(output_dir, filename)

    doc = SimpleDocTemplate(filepath, pagesize=letter,
                            topMargin=0.75 * inch, bottomMargin=0.75 * inch)
    story = []

    # Title
    story.append(Paragraph(title, TITLE_STYLE))
    story.append(Paragraph("Acme Corporation — Confidential", STYLES["Italic"]))
    story.append(Spacer(1, 20))

    for heading, paragraphs in sections:
        story.append(Paragraph(heading, HEADING_STYLE))
        for para in paragraphs:
            story.append(Paragraph(para, BODY_STYLE))
        story.append(Spacer(1, 8))

    doc.build(story)
    print(f"Generated: {filepath}")


def generate_leave_policy():
    sections = [
        ("1. Annual Leave", [
            "All full-time employees are entitled to 20 days of paid annual leave per calendar year. "
            "Leave accrues at a rate of 1.67 days per month of continuous service.",
            "Unused annual leave may be carried forward up to a maximum of 5 days into the next calendar year. "
            "Any leave beyond 5 days will be forfeited unless approved by the department head.",
            "Leave requests must be submitted at least 2 weeks in advance through the HR portal. "
            "Requests during peak business periods (Q4) require manager and director approval.",
        ]),
        ("2. Sick Leave", [
            "Employees are entitled to 10 days of paid sick leave per year. Sick leave does not carry over.",
            "For absences exceeding 3 consecutive days, a medical certificate from a licensed physician "
            "must be submitted to HR within 5 business days of returning to work.",
            "Employees who exhaust sick leave may use annual leave or apply for unpaid medical leave.",
        ]),
        ("3. Parental Leave", [
            "Primary caregivers are entitled to 16 weeks of paid parental leave at full salary. "
            "Secondary caregivers are entitled to 4 weeks of paid parental leave.",
            "Parental leave must be taken within 12 months of the birth or adoption of a child. "
            "Leave may be taken in a single continuous block or in up to two separate periods.",
            "Employees must notify HR at least 8 weeks before the expected start of parental leave.",
        ]),
        ("4. Bereavement Leave", [
            "Employees are entitled to 5 days of paid bereavement leave for the death of an immediate "
            "family member (spouse, child, parent, sibling). 3 days are provided for extended family.",
        ]),
        ("5. Public Holidays", [
            "The company observes 10 public holidays per year as determined annually by the executive team. "
            "The holiday calendar is published by January 15 each year.",
            "Employees required to work on a public holiday will receive compensatory time off or "
            "overtime pay at 1.5x their regular rate, at the manager's discretion.",
        ]),
    ]
    build_pdf("leave-policy.pdf", "Leave Policy", sections)


def generate_it_policy():
    sections = [
        ("1. Company Devices", [
            "All employees will receive a company-issued laptop configured with standard security software "
            "including endpoint protection, disk encryption, and mobile device management (MDM).",
            "Personal use of company devices is permitted in moderation but must not interfere with work "
            "obligations or violate any company policies.",
            "Lost or stolen devices must be reported to the IT Help Desk within 2 hours. "
            "IT will remotely wipe the device to protect company data.",
        ]),
        ("2. VPN and Remote Access", [
            "Employees working remotely must connect to the corporate VPN before accessing any internal "
            "systems, including email, file shares, and internal applications.",
            "VPN credentials are unique to each employee and must never be shared. "
            "Multi-factor authentication (MFA) is required for all VPN connections.",
            "Public Wi-Fi networks may only be used with the VPN active. Employees should avoid "
            "accessing sensitive data from untrusted networks whenever possible.",
        ]),
        ("3. Software Installation", [
            "Only IT-approved software may be installed on company devices. The approved software catalog "
            "is available on the IT intranet portal.",
            "Requests for new software must be submitted through the IT Service Desk with a business "
            "justification. Approval typically takes 3-5 business days.",
            "Installing unlicensed, pirated, or unauthorized software is strictly prohibited and may "
            "result in disciplinary action up to and including termination.",
        ]),
        ("4. Data Security", [
            "Confidential data must be stored only on company-approved cloud storage (Google Drive, "
            "SharePoint) or encrypted local drives. USB drives are prohibited for data transfer.",
            "Emails containing sensitive information must use the company's encrypted email service. "
            "Never send passwords, API keys, or credentials via email or chat.",
            "All employees must complete the annual cybersecurity training by December 31 each year.",
        ]),
        ("5. Acceptable Use", [
            "Company internet and email services are provided for business purposes. Limited personal use "
            "is acceptable but must not include illegal activities, harassment, or access to inappropriate content.",
            "IT reserves the right to monitor network traffic and email communications to ensure compliance "
            "with company policies and applicable laws.",
        ]),
    ]
    build_pdf("it-policy.pdf", "IT & Technology Policy", sections)


def generate_code_of_conduct():
    sections = [
        ("1. Professional Behavior", [
            "All employees are expected to conduct themselves with integrity, respect, and professionalism "
            "in all work-related interactions, whether in-person, virtual, or written.",
            "Harassment, discrimination, bullying, or intimidation of any kind will not be tolerated. "
            "This includes behavior based on race, gender, age, religion, disability, sexual orientation, "
            "or any other protected characteristic.",
            "Employees should foster an inclusive environment where diverse perspectives are valued "
            "and all team members feel safe to contribute.",
        ]),
        ("2. Communication Standards", [
            "Professional communication is expected in all channels including email, Slack, video calls, "
            "and in-person meetings. Use clear, respectful, and constructive language.",
            "Respond to internal communications within one business day. For urgent matters, use the "
            "designated escalation channels rather than repeated follow-ups.",
            "Meeting etiquette: arrive on time, come prepared, keep cameras on during video calls when "
            "feasible, and respect others' speaking time.",
        ]),
        ("3. Conflict of Interest", [
            "Employees must disclose any personal, financial, or business relationships that could "
            "create a real or perceived conflict of interest with their role at the company.",
            "Outside employment or consulting work must be disclosed to and approved by HR. Activities "
            "that compete with or could harm the company are prohibited.",
        ]),
        ("4. Confidentiality", [
            "Employees must protect confidential company information including trade secrets, financial "
            "data, customer information, and strategic plans.",
            "Confidentiality obligations continue after employment ends as specified in the employment "
            "agreement. Violations may result in legal action.",
        ]),
        ("5. Reporting Violations", [
            "Employees who witness or experience violations of this code should report them to their "
            "manager, HR, or through the anonymous ethics hotline at ethics@acmecorp.com.",
            "The company prohibits retaliation against employees who report violations in good faith. "
            "All reports will be investigated promptly and confidentially.",
        ]),
        ("6. Consequences", [
            "Violations of this Code of Conduct may result in disciplinary action ranging from a verbal "
            "warning to termination of employment, depending on the severity and frequency of the violation.",
            "Serious violations including fraud, theft, violence, or illegal activity will result in "
            "immediate termination and may be reported to law enforcement.",
        ]),
    ]
    build_pdf("code-of-conduct.pdf", "Code of Conduct", sections)


if __name__ == "__main__":
    print("Generating sample HR policy documents...")
    generate_leave_policy()
    generate_it_policy()
    generate_code_of_conduct()
    print("\nAll documents generated in docs/sample-policies/")
    print("Upload them to S3 with:")
    print("  aws s3 sync docs/sample-policies/ s3://<your-documents-bucket>/")
