# Site & Worker Management App - Legal Compliance Enhancement Plan

## Overview
Multi-phase implementation plan to add legal compliance features and enhance the app's capabilities for construction site management.

---

## PHASE 1: Worker Documentation & Legal Foundation (v2.0.0)
**Target:** 2-3 weeks

### Model Changes
- **worker_model.dart**: Add new fields
  - `licenseNumber: String?`
  - `licenseExpiry: DateTime?`
  - `licenseImagePath: String?`
  - `idDocumentPath: String?`
  - `insurancePolicyNumber: String?`
  - `insuranceExpiry: DateTime?`
  - `safetyCertPath: String?`
  - `signedAgreementDate: DateTime?`
  - `signedAgreementIp: String?`

### UI Requirements
1. **Worker Form Screen** (enhanced)
   - Document upload section (ID, License, Insurance)
   - Digital signature pad for worker agreements
   - Expiry date reminders

2. **Data Retention Settings Screen**
   - Retention period selection (1yr, 3yr, 7yr, Never auto-delete)
   - Auto-archive toggle

### Database Schema Updates
```sql
ALTER TABLE workers ADD COLUMN license_number TEXT;
ALTER TABLE workers ADD COLUMN license_expiry INTEGER;
ALTER TABLE workers ADD COLUMN license_image_path TEXT;
ALTER TABLE workers ADD COLUMN id_document_path TEXT;
ALTER TABLE workers ADD COLUMN insurance_policy_number TEXT;
ALTER TABLE workers ADD COLUMN insurance_expiry INTEGER;
ALTER TABLE workers ADD COLUMN safety_cert_path TEXT;
ALTER TABLE workers ADD COLUMN signed_agreement_date INTEGER;
ALTER TABLE workers ADD COLUMN signed_agreement_ip TEXT;
```

### Permissions Required
- Camera (for document scanning)
- Storage (for document saving)
- Internet (for document verification if needed)

### Testing Requirements
- Document upload/download tests
- Signature capture validation
- Expiry date alert tests
- Data export tests

### Legal References
- India DPDP Act 2023 - Document retention requirements
- GDPR Article 30 - Records of processing activities

---

## PHASE 2: Labor Law Compliance Features (v2.1.0)
**Target:** 3-4 weeks

### Model Changes
- **attendance_model.dart**: 
  - Add `restBreakTaken: bool`
  - Add `restBreakTime: DateTime?`
  - Add `hoursWorked: double`
  - Add `overtimeHours: double`

- **Create new overtime_rule_model.dart**:
  - `jurisdiction: String`
  - `dailyLimit: int` (hours)
  - `weeklyLimit: int` (hours)
  - `overtimeMultiplier: double`
  - `restPeriodMinutes: int`

### UI Requirements
1. **Rest Break Timer**
   - Desktop notification when 4-5 hours passed
   - In-app timer with snooze option

2. **Overtime Dashboard**
   - Weekly hours visualization
   - Overtime rate calculator
   - Limit warning alerts

3. **Attendance Reports**
   - Export as PDF/CSV
   - Compliance format templates

### Database Schema Updates
```sql
ALTER TABLE attendance ADD COLUMN rest_break_taken INTEGER DEFAULT 0;
ALTER TABLE attendance ADD COLUMN rest_break_time INTEGER;
ALTER TABLE attendance ADD COLUMN hours_worked REAL DEFAULT 0;
ALTER TABLE attendance ADD COLUMN overtime_hours REAL DEFAULT 0;

CREATE TABLE overtime_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  jurisdiction TEXT NOT NULL,
  daily_limit INTEGER NOT NULL,
  weekly_limit INTEGER NOT NULL,
  overtime_multiplier REAL NOT NULL,
  rest_period_minutes INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
```

### Testing Requirements
- Overtime calculation accuracy tests
- Rest period enforcement tests
- Reporting format validation
- Jurisdiction switching tests

### Legal References
- Minimum Wage Act 1948 (India)
- Working Hours Regulation
- State-specific labor laws

---

## PHASE 3: Safety & Incident Management (v2.2.0)
**Target:** 3-4 weeks

### Model Changes
- **Create hazard_model.dart**:
  ```dart
  class Hazard {
    int? id;
    int siteId;
    String description;
    String location;
    String severity; // low, medium, high, critical
    String reportedBy;
    DateTime reportedAt;
    String? photoPath;
    String status; // open, in_progress, resolved, closed
    String resolutionNotes;
  }
  ```

- **Create incident_model.dart**:
  ```dart
  class Incident {
    int? id;
    int siteId;
    String description;
    double? injurySeverity; // 1-10 scale
    String reportedBy;
    DateTime reportedAt;
    DateTime incidentDate;
    List<String> witnesses;
    String? photoPaths;
    String investigator;
    String findings;
    String correctiveActions;
    String status; // open, investigating, closed
  }
  ```

### UI Requirements
1. **Hazard Reporting Screen**
   - Photo capture
   - Location tagging
   - Severity selector
   - Submit button

2. **Incident Management Screen**
   - Detailed incident log
   - Investigation workflow
   - Corrective action tracker
   - Witness management

3. **Safety Training Records**
   - Training completion tracker
   - Certificate expiry alerts
   - Required training list

### Database Schema Updates
```sql
CREATE TABLE hazards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  site_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  severity TEXT NOT NULL,
  reported_by TEXT NOT NULL,
  reported_at INTEGER NOT NULL,
  photo_path TEXT,
  status TEXT NOT NULL DEFAULT 'open',
  resolution_notes TEXT,
  FOREIGN KEY(site_id) REFERENCES sites(id)
);

CREATE TABLE incidents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  site_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  injury_severity REAL,
  reported_by TEXT NOT NULL,
  reported_at INTEGER NOT NULL,
  incident_date INTEGER NOT NULL,
  witnesses TEXT,
  photo_paths TEXT,
  investigator TEXT,
  findings TEXT,
  corrective_actions TEXT,
  status TEXT NOT NULL DEFAULT 'open',
  FOREIGN KEY(site_id) REFERENCES sites(id)
);

CREATE TABLE safety_training (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  worker_id INTEGER NOT NULL,
  training_name TEXT NOT NULL,
  completed_date INTEGER NOT NULL,
  expiry_date INTEGER NOT NULL,
  certificate_path TEXT,
  FOREIGN KEY(worker_id) REFERENCES workers(id)
);
```

### Testing Requirements
- Photo upload limits and compression
- Location accuracy validation
- Email notifications for critical hazards
- PDF report generation tests

### Legal References
- Occupational Safety & Health Act
- Construction (Safety) Requirements
- Workers' compensation reporting

---

## PHASE 4: Audit Trail & Compliance Logging (v2.3.0)
**Target:** 2-3 weeks

### Model Changes
- **Create audit_log_model.dart**:
  ```dart
  class AuditLog {
    int? id;
    String action; // create, update, delete, approve, reject
    String tableName;
    int recordId;
    String userId;
    String userName;
    DateTime timestamp;
    String ipAddress;
    String userAgent;
    Map<String, dynamic> oldValues;
    Map<String, dynamic> newValues;
    String purpose; // compliance purpose
  }
  ```

### UI Requirements
1. **Audit Log Viewer**
   - Filter by date range, user, action type
   - Export as CSV/JSON
   - Search functionality

2. **Data Processing Purpose Screen**
   - Select purpose for data use
   - Consent tracking
   - Purpose history

### Database Schema Updates
```sql
CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  old_values TEXT,
  new_values TEXT,
  purpose TEXT
);

CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
```

### Testing Requirements
- Log completeness verification
- Performance tests (log volume impact)
- Export validation
- GDPR deletion log entry

### Legal References
- GDPR Article 30 - Records of processing activities
- CCPA audit trail requirements
- DPDP Act data processing records

---

## PHASE 5: Financial Compliance (v2.4.0)
**Target:** 4-5 weeks

### Model Changes
- **payroll_model.dart**: Add fields
  - `grossPay: double`
  - `deductions: double`
  - `netPay: double`
  - `taxDeductions: double`
  - `generatedAt: DateTime`
  - `generatedBy: String`

- **Create tax_calculation_model.dart**:
  ```dart
  class TaxRule {
    String jurisdiction;
    double threshold;
    double rate;
    String type; // income, sgst, cgst, etc.
  }
  ```

### UI Requirements
1. **Pay Stub Generator**
   - Preview before generation
   - Digital signature placement
   - Export as PDF

2. **Tax Configuration Screen**
   - Tax rates by jurisdiction
   - Threshold settings
   - Calculation preview

3. **Payroll Export**
   - CSV for accounting software
   - XBRL format (for regulatory reporting)
   - Batch export options

### Database Schema Updates
```sql
ALTER TABLE payroll ADD COLUMN gross_pay REAL;
ALTER TABLE payroll ADD COLUMN deductions REAL;
ALTER TABLE payroll ADD COLUMN net_pay REAL;
ALTER TABLE payroll ADD COLUMN tax_deductions REAL;
ALTER TABLE payroll ADD COLUMN generated_at INTEGER;
ALTER TABLE payroll ADD COLUMN generated_by TEXT;

CREATE TABLE tax_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  jurisdiction TEXT NOT NULL,
  threshold REAL NOT NULL,
  rate REAL NOT NULL,
  type TEXT NOT NULL,
  effective_from INTEGER NOT NULL,
  effective_to INTEGER
);
```

### Testing Requirements
- Tax calculation accuracy tests
- Pay stub format validation
- Export format compliance
- Digital signature verification

### Legal References
- Income Tax Act requirements
- Provincial tax regulations
- Payroll reporting obligations

---

## PHASE 6: Data Privacy Controls (v2.5.0)
**Target:** 3-4 weeks

### Model Changes
- **Create consent_model.dart**:
  ```dart
  class Consent {
    String userId;
    DateTime consentDate;
    List<String> purposes; // what data is used for
    DateTime? withdrawnDate;
    String version;
  }
  ```

### UI Requirements
1. **Consent Management Screen**
   - List of data processing purposes
   - Individual consent toggles
   - Consent history

2. **Data Export Request**
   - Generate complete data export
   - Format selection (JSON, CSV)
   - Download link generation

3. **Right to Be Forgotten**
   - Confirmation screen
   - Legal basis selection
   - Deletion confirmation with timeline

### Database Schema Updates
```sql
CREATE TABLE consents (
  user_id TEXT PRIMARY KEY,
  consent_date INTEGER NOT NULL,
  purposes TEXT NOT NULL,
  withdrawn_date INTEGER,
  version TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES workers(id)
);

CREATE TABLE data_deletion_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  request_date INTEGER NOT NULL,
  legal_basis TEXT NOT NULL,
  deletion_scheduled INTEGER NOT NULL,
  deletion_completed INTEGER,
  notes TEXT,
  FOREIGN KEY(user_id) REFERENCES workers(id)
);
```

### Testing Requirements
- Consent withdrawal workflow
- Data export completeness check
- Deletion verification
- Retention policy enforcement

### Legal References
- GDPR Articles 15, 17, 20 - Right to access, portability, erasure
- CCPA consumer rights
- India DPDP Act data principal rights

---

## PHASE 7: Advanced Features (v3.0.0)
**Target:** 4-6 weeks

### Model Changes
- **Create biometric_log_model.dart**:
  ```dart
  class BiometricLog {
    int? id;
    int workerId;
    DateTime timestamp;
    String location;
    double confidence;
    String method; // fingerprint, face, iris
  }
  ```

- **Create qrbadge_model.dart**:
  ```dart
  class QRBadge {
    String workerId;
    String encodedData; // encrypted worker info
    DateTime generatedAt;
    DateTime expiresAt;
    bool isActive;
  }
  ```

### UI Requirements
1. **Biometric Attendance**
   - Enrollment flow
   - Attendance capture
   - Fallback to manual

2. **QR Badge Screen**
   - Generate badge
   - Print preview
   - Badge status tracker

3. **Offline Mode**
   - Local data storage
   - Sync when online
   - Compliance flag for offline entries

### Database Schema Updates
```sql
CREATE TABLE biometric_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  worker_id INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  location TEXT NOT NULL,
  confidence REAL NOT NULL,
  method TEXT NOT NULL,
  device_info TEXT,
  FOREIGN KEY(worker_id) REFERENCES workers(id)
);

CREATE TABLE qr_badges (
  worker_id TEXT PRIMARY KEY,
  encoded_data TEXT NOT NULL,
  generated_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1
);
```

### Testing Requirements
- Biometric accuracy tests
- QR scan reliability
- Offline sync validation
- Multi-language UI verification

### Legal References
- Biometric data protection laws
- Digital signature regulations (ESIGN Act equivalent)
- Accessibility compliance

---

## Version Timeline Summary

| Version | Phase | Duration | Key Features |
|---------|-------|----------|--------------|
| 2.0.0 | Phase 1 | 2-3w | Worker docs, digital signatures |
| 2.1.0 | Phase 2 | 3-4w | Labor law compliance |
| 2.2.0 | Phase 3 | 3-4w | Safety & incident mgmt |
| 2.3.0 | Phase 4 | 2-3w | Audit trail & logging |
| 2.4.0 | Phase 5 | 4-5w | Financial compliance |
| 2.5.0 | Phase 6 | 3-4w | Data privacy controls |
| 3.0.0 | Phase 7 | 4-6w | Advanced features |

---

## Next Steps

1. **Review & Prioritize**: Select which phases to implement first based on regulatory deadlines
2. **Resource Planning**: Estimate development team size for each phase
3. **Legal Consultation**: Validate compliance requirements with legal experts in target jurisdiction
4. **Pilot Testing**: Choose 1-2 phases for pilot implementation with real users