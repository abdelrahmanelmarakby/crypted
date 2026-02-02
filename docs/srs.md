# AgencyOS - Software Requirements Specification (SRS)

**Document Version:** 1.0  
**Date:** February 2, 2026  
**Prepared by:** Abwab Digital (team@abwabdigital.com)  
**Classification:** Confidential - Internal & Stakeholder Use  
**Standard:** IEEE 830-1998 (Adapted)  
**Document ID:** AOS-SRS-2026-001  

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Architecture](#3-system-architecture)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Data Model](#6-data-model)
7. [API Design](#7-api-design)
8. [AI Engine Specification (Gemini Integration)](#8-ai-engine-specification-gemini-integration)
9. [Gamification Engine Specification](#9-gamification-engine-specification)
10. [Audit & Compliance Specification](#10-audit--compliance-specification)
11. [Security Requirements](#11-security-requirements)
12. [External Interface Requirements](#12-external-interface-requirements)
13. [Self-Hosted Deployment Specification](#13-self-hosted-deployment-specification)
14. [Appendices](#14-appendices)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) defines the functional and non-functional requirements for **AgencyOS**, an enterprise-grade, AI-native, modular ERP platform for software development and marketing agencies. This document serves as the primary reference for:

- **Engineering teams** implementing the system
- **QA teams** developing test plans and acceptance tests
- **Product managers** validating feature completeness
- **Stakeholders** reviewing technical feasibility
- **External auditors** assessing compliance readiness

### 1.2 Scope

AgencyOS is a self-hosted, web-based ERP platform consisting of 30 configurable modules spanning project management, client relations, financial operations, human resources, software development, marketing campaigns, gamification, AI-powered analytics, and audit/compliance. The system is built on Next.js (frontend), Node.js (backend), and PostgreSQL (database), deployed via Docker/Kubernetes on customer infrastructure.

**In Scope:**
- All 30 modules as defined in the Business Analysis document
- Gemini AI integration for intelligent features
- Professional gamification engine
- Enterprise audit and compliance system
- Self-hosted deployment with Docker/Kubernetes
- REST and GraphQL APIs
- Pre-built integrations with 15+ third-party services
- Multi-language support (English, Arabic with RTL)
- White-label and multi-brand capabilities

**Out of Scope:**
- Native mobile applications (web-responsive only for V1; mobile apps planned for V2)
- SaaS/cloud-hosted deployment (self-hosted only for V1)
- Custom hardware integrations
- Blockchain-based audit trails (standard cryptographic signing instead)
- Real-time video conferencing (integration with external services instead)

### 1.3 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|---|---|
| **API** | Application Programming Interface |
| **BYOK** | Bring Your Own Key (customer provides their own AI API key) |
| **CQRS** | Command Query Responsibility Segregation |
| **CRUD** | Create, Read, Update, Delete |
| **DTO** | Data Transfer Object |
| **ERP** | Enterprise Resource Planning |
| **HATEOAS** | Hypermedia as the Engine of Application State |
| **JWT** | JSON Web Token |
| **MinIO** | S3-compatible object storage |
| **MFA** | Multi-Factor Authentication |
| **ORM** | Object-Relational Mapping |
| **RBAC** | Role-Based Access Control |
| **RTL** | Right-to-Left (text direction) |
| **SSE** | Server-Sent Events |
| **SSO** | Single Sign-On |
| **TOTP** | Time-based One-Time Password |
| **WebSocket** | Full-duplex communication protocol |

### 1.4 References

| Document | Version | Description |
|---|---|---|
| AgencyOS Business Analysis | 1.0 | Market analysis, personas, business objectives |
| AgencyOS User Stories | 1.0 | 198 user stories with BDD acceptance criteria |
| IEEE 830-1998 | -- | Recommended practice for SRS |
| OWASP Top 10 (2025) | 2025 | Web application security risks |
| GDPR Regulation | EU 2016/679 | General Data Protection Regulation |
| SOC 2 Type II | -- | Service Organization Control criteria |
| ISO 27001 | 2022 | Information security management |

### 1.5 Document Conventions

- Requirements are identified by: `[MODULE]-[TYPE]-[NUMBER]` (e.g., `AUTH-FR-001`)
- **FR** = Functional Requirement
- **NFR** = Non-Functional Requirement
- Priority levels: **P0** (Critical), **P1** (Important), **P2** (Nice-to-have)
- Each requirement traces to one or more user stories from the User Stories document

---

## 2. Overall Description

### 2.1 Product Perspective

AgencyOS is a new, self-contained product that replaces the combination of 8-15 separate SaaS tools typically used by digital agencies. It operates as a monolithic-modular application (modular code structure within a single deployable unit) for simpler deployment, with the option to extract modules into microservices as scale demands.

### 2.2 Product Functions (High-Level)

| Function Group | Modules | Description |
|---|---|---|
| **Operations Management** | Projects, Tasks, Resources, Time Tracking | Day-to-day work planning and execution |
| **Client Management** | CRM, Client Portal, Proposals, Contracts | Client lifecycle from lead to retention |
| **Financial Management** | Invoicing, Expenses, Budgets, P&L | Revenue, cost, and profitability management |
| **People Management** | HR, Recruitment, OKRs, Knowledge Base | Employee lifecycle and development |
| **Agency Delivery** | Software Dev, Marketing, Creative, QA | Discipline-specific delivery workflows |
| **Intelligence** | AI Engine, Reporting, Analytics | AI-powered insights and business intelligence |
| **Engagement** | Gamification, Communication Hub | Team motivation and collaboration |
| **Governance** | Audit, Compliance, Workflow Automation | Accountability, compliance, and process control |
| **Platform** | Auth, Org Management, Integrations, White-Label, Assets | Infrastructure and configuration |

### 2.3 User Classes and Characteristics

| User Class | Technical Skill | Frequency | Access Level | Key Modules |
|---|---|---|---|---|
| Super Admin | Expert | Daily | Full system | All + Admin |
| Agency Owner | Medium | Daily | Full business | Dashboards, Finance, P&L, OKRs |
| Project Manager | High | All day | Projects + Clients | Projects, Tasks, CRM, Resources |
| Team Lead | High | All day | Team scope | Tasks, Sprints, Team Dashboard |
| Developer | Very High | All day | Tasks + Code | Tasks, Software Dev, Time, KB |
| Designer | Medium | All day | Tasks + Assets | Tasks, Creative, Time |
| Marketer | Medium-High | All day | Campaigns | Tasks, Marketing, Content, Time |
| HR Manager | Medium | Daily | People | HR, Recruitment, OKRs |
| Finance Manager | Medium | Daily | Financial | Finance, Invoicing, Audit |
| Operations Manager | Medium-High | Daily | Cross-module | Automation, Reports, Resources |
| Client (External) | Low-Medium | Weekly | Portal only | Client Portal |

### 2.4 Operating Environment

| Component | Requirement |
|---|---|
| **Client Browser** | Chrome 90+, Firefox 90+, Safari 15+, Edge 90+ |
| **Server OS** | Linux (Ubuntu 22.04+, Debian 12+, RHEL 9+) |
| **Container Runtime** | Docker 24+ or containerd 1.7+ |
| **Orchestration** | Docker Compose (single-node) or Kubernetes 1.28+ (multi-node) |
| **Database** | PostgreSQL 16+ |
| **Cache** | Redis 7+ |
| **Object Storage** | MinIO (self-hosted S3-compatible) |
| **Search** | PostgreSQL Full-Text Search (Elasticsearch optional for large deployments) |
| **Reverse Proxy** | Nginx, Traefik, or Caddy (SSL termination) |
| **Minimum Hardware** | 4 CPU cores, 16GB RAM, 100GB SSD (small deployment, <50 users) |
| **Recommended Hardware** | 8+ CPU cores, 32GB+ RAM, 500GB+ SSD (medium, 50-200 users) |
| **Network** | HTTPS required, WebSocket support, outbound HTTPS for AI API |

### 2.5 Design and Implementation Constraints

| Constraint | Description |
|---|---|
| **Technology Stack** | Next.js 15+ (frontend), Node.js 22+ (backend), PostgreSQL 16+ (database), Redis 7+ (cache), MinIO (storage) |
| **Language** | TypeScript for all application code (frontend and backend) |
| **ORM** | Prisma ORM for database access |
| **API Framework** | Express.js or Fastify with tRPC for type-safe API |
| **Authentication** | JSON Web Tokens (JWT) with refresh token rotation |
| **AI Provider** | Google Gemini API (primary), with abstraction layer for alternatives |
| **Deployment** | Docker containers, Docker Compose for single-node, Helm charts for Kubernetes |
| **Self-Hosted** | All data must remain on customer infrastructure; no telemetry sent to vendor |
| **Offline Resilience** | Core functionality must work if the Gemini API is unreachable |
| **Browser Support** | Last 2 major versions of Chrome, Firefox, Safari, Edge |
| **Accessibility** | WCAG 2.1 Level AA compliance |
| **Internationalization** | i18n framework from day one, supporting LTR and RTL layouts |

### 2.6 Assumptions and Dependencies

**Assumptions:**
1. Customers have technical capability to deploy Docker containers
2. Customers have reliable internet connectivity for AI features (Gemini API)
3. Customers provide their own SSL certificates for HTTPS
4. PostgreSQL performance is sufficient for most deployments without read replicas
5. Users access the platform via modern web browsers

**Dependencies:**
1. Google Gemini API availability and pricing stability
2. Third-party OAuth providers for SSO (Google, Microsoft, Okta)
3. Third-party integration APIs (GitHub, Slack, Stripe, etc.)
4. Prisma ORM compatibility with PostgreSQL features
5. Next.js framework stability and long-term support

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
                                    +-------------------+
                                    |   Load Balancer   |
                                    |   (Nginx/Traefik) |
                                    +--------+----------+
                                             |
                              +--------------+--------------+
                              |                             |
                    +---------v----------+      +-----------v-----------+
                    |   Next.js App      |      |   Next.js App         |
                    |   (Frontend +      |      |   (Frontend +         |
                    |    API Routes)     |      |    API Routes)        |
                    |                    |      |                       |
                    |   Port: 3000       |      |   Port: 3000          |
                    +--------+-----------+      +-----------+-----------+
                             |                              |
                    +--------v------------------------------v----------+
                    |              Shared Services Layer                |
                    |                                                   |
                    |  +----------+  +--------+  +---------+  +------+ |
                    |  | Auth     |  | AI     |  | Event   |  | Job  | |
                    |  | Service  |  | Router |  | Bus     |  | Queue| |
                    |  +----------+  +--------+  +---------+  +------+ |
                    +--------+-----------+-----------+---------+-------+
                             |           |           |         |
              +--------------+-----------+-----------+---------+-------+
              |              |           |           |                  |
    +---------v---+ +--------v--+ +------v----+ +---v-------+ +-------v-----+
    | PostgreSQL  | |   Redis   | |   MinIO   | |  Gemini   | | Email (SMTP)|
    | (Primary)   | |  (Cache + | | (Object   | |  API      | |             |
    |             | |   Queue)  | |  Storage) | | (External)| |             |
    | Port: 5432  | | Port: 6379| | Port: 9000| |           | |             |
    +-------------+ +-----------+ +-----------+ +-----------+ +-------------+
```

### 3.2 Application Architecture

AgencyOS follows a **Modular Monolith** architecture pattern:

```
src/
├── core/                          # Shared kernel
│   ├── auth/                      # Authentication & authorization
│   ├── database/                  # Prisma client, migrations
│   ├── cache/                     # Redis cache layer
│   ├── storage/                   # MinIO file operations
│   ├── ai/                        # AI abstraction layer
│   ├── events/                    # Event bus (publish/subscribe)
│   ├── jobs/                      # Background job processor
│   ├── audit/                     # Audit logging
│   ├── i18n/                      # Internationalization
│   └── utils/                     # Shared utilities
│
├── modules/                       # Feature modules (bounded contexts)
│   ├── organization/
│   │   ├── organization.module.ts
│   │   ├── organization.service.ts
│   │   ├── organization.controller.ts
│   │   ├── organization.repository.ts
│   │   ├── dto/
│   │   ├── entities/
│   │   └── __tests__/
│   ├── projects/
│   ├── tasks/
│   ├── crm/
│   ├── finance/
│   ├── hr/
│   ├── time-tracking/
│   ├── resources/
│   ├── documents/
│   ├── communication/
│   ├── reporting/
│   ├── software-dev/
│   ├── marketing/
│   ├── creative/
│   ├── client-portal/
│   ├── gamification/
│   ├── ai-engine/
│   ├── audit-compliance/
│   ├── integrations/
│   ├── knowledge-base/
│   ├── recruitment/
│   ├── contracts/
│   ├── proposals/
│   ├── qa/
│   ├── support/
│   ├── okr/
│   ├── automation/
│   ├── white-label/
│   └── assets/
│
├── app/                           # Next.js pages/routes (frontend)
│   ├── (auth)/                    # Auth pages (login, register)
│   ├── (dashboard)/               # Authenticated pages
│   │   ├── projects/
│   │   ├── tasks/
│   │   ├── clients/
│   │   └── ...
│   ├── portal/                    # Client portal pages
│   └── api/                       # Next.js API routes
│       ├── v1/                    # REST API v1
│       └── graphql/               # GraphQL endpoint
│
├── components/                    # Shared React components
│   ├── ui/                        # Base UI components (Button, Input, etc.)
│   ├── layout/                    # Layout components (Sidebar, Header)
│   ├── data-display/              # Tables, Charts, Cards
│   ├── forms/                     # Form components
│   └── modules/                   # Module-specific components
│
└── lib/                           # Client-side utilities
    ├── api/                       # API client
    ├── hooks/                     # React hooks
    ├── stores/                    # State management (Zustand)
    └── utils/                     # Client utilities
```

### 3.3 Module Communication

Modules communicate through well-defined interfaces:

```
Module A                    Event Bus                    Module B
   |                           |                            |
   |-- emits event ----------->|                            |
   |                           |--- delivers event -------->|
   |                           |                            |
   |                    Direct Service Call                  |
   |-- calls service ---------------------------------------->|
   |<-- returns result ----------------------------------------|
```

**Rules:**
1. Modules MUST NOT directly access another module's database tables
2. Modules communicate via: (a) the event bus for async operations, (b) service interfaces for sync operations
3. Each module owns its database tables (no cross-module JOINs)
4. Cross-module queries use the Reporting module's materialized views
5. Module dependencies are explicitly declared in `module.ts`

### 3.4 Data Flow Architecture

```
Client (Browser)
     |
     | HTTPS
     v
+----+----+
|  Next.js |
|  Server  |
+----+----+
     |
     | Server Components (SSR) + API Routes
     v
+----+----+
| Service  |
|  Layer   |
+----+----+
     |
     |--- Business Logic ---+--- Validation ---+--- Authorization
     |                       |                   |
     v                       v                   v
+----+----+          +-------+------+    +-------+------+
|Repository|         | Event Bus    |    | Audit Logger |
|  Layer   |         | (Redis Pub/  |    | (Append-only)|
+----+----+          |  Sub)        |    +--------------+
     |               +--------------+
     |
     v
+----+----+
| Prisma  |
|  ORM    |
+----+----+
     |
     v
+----+----+
|PostgreSQL|
+----------+
```

### 3.5 Real-Time Architecture

Real-time features (chat, notifications, live updates) use a dual approach:

```
Browser                        Server
  |                               |
  |--- WebSocket Connect -------->| (Long-lived connection)
  |                               |
  |<-- Push: Notification --------|
  |<-- Push: Chat Message --------|
  |<-- Push: Task Update ----------|
  |                               |
  |--- SSE Connect (fallback) --->| (For environments blocking WS)
  |<-- Event Stream --------------|
```

**Implementation:**
- **Primary:** WebSocket via Socket.io
- **Fallback:** Server-Sent Events (SSE)
- **Pub/Sub:** Redis for horizontal scaling (multiple server instances share events)

### 3.6 Caching Strategy

```
Request Flow:

1. Browser Cache (Service Worker) → 2. CDN/Edge Cache → 3. Redis Cache → 4. PostgreSQL

Cache Levels:
┌─────────────────────────────────────────────────────────┐
│ L1: In-Memory (Node.js process)   TTL: 30 seconds      │
│     - Hot config, user sessions, RBAC permissions       │
├─────────────────────────────────────────────────────────┤
│ L2: Redis                          TTL: 5-60 minutes    │
│     - Query results, dashboard data, API responses      │
├─────────────────────────────────────────────────────────┤
│ L3: PostgreSQL Materialized Views  Refresh: 15 minutes  │
│     - Complex aggregations, cross-module reports        │
├─────────────────────────────────────────────────────────┤
│ L4: Browser Cache                  TTL: varies          │
│     - Static assets (immutable), API responses (stale-  │
│       while-revalidate)                                 │
└─────────────────────────────────────────────────────────┘
```

**Cache Invalidation:**
- Event-driven: When data changes, the event bus triggers cache invalidation for affected keys
- TTL-based: All cached items have a time-to-live to prevent stale data
- Manual: Admin can flush caches from the System Health dashboard

### 3.7 Background Job Architecture

```
Job Producers                    Job Queue (Redis/BullMQ)           Job Consumers
                                                                    
API Routes ───────┐                                                 
Event Handlers ───┤         ┌──────────────────────┐               
Cron Scheduler ───┼────────>│  Priority Queues     │──────────> Worker Processes
AI Engine ────────┤         │                      │               
Webhooks ─────────┘         │  ├── critical        │           ┌──> Email Sender
                            │  ├── high            │           ├──> AI Processor
                            │  ├── normal          │           ├──> Report Generator
                            │  └── low             │           ├──> Webhook Dispatcher
                            │                      │           ├──> Audit Indexer
                            │  Features:           │           └──> Integration Sync
                            │  - Retry w/ backoff  │               
                            │  - Dead letter queue │               
                            │  - Rate limiting     │               
                            │  - Job scheduling    │               
                            └──────────────────────┘               
```

---

## 4. Functional Requirements

### 4.1 Module: Authentication & Identity Management

#### AUTH-FR-001: User Authentication
**Priority:** P0 | **Traces to:** AUTH-001, AUTH-002

The system SHALL support email/password authentication with the following requirements:
- Passwords MUST be hashed using bcrypt with a cost factor of 12+
- Sessions MUST use JWT with short-lived access tokens (15 minutes) and long-lived refresh tokens (7 days)
- Refresh token rotation MUST be implemented (each refresh issues a new refresh token)
- Concurrent sessions MUST be supported with a configurable limit (default: 5 devices)
- Failed login attempts MUST trigger account lockout after 5 consecutive failures (15-minute lockout)
- All authentication events MUST be logged to the audit trail

#### AUTH-FR-002: Multi-Factor Authentication
**Priority:** P0 | **Traces to:** AUTH-003

The system SHALL support MFA with:
- TOTP (RFC 6238) via authenticator apps (Google Authenticator, Authy, 1Password)
- Email-based OTP as an alternative
- 10 backup recovery codes generated at MFA enrollment
- Organization-wide MFA enforcement option (Super Admin)
- Remember trusted devices for 30 days (configurable)

#### AUTH-FR-003: Single Sign-On
**Priority:** P1 | **Traces to:** AUTH-004

The system SHALL support SSO via:
- SAML 2.0 (for enterprise identity providers: Okta, Azure AD, OneLogin)
- OpenID Connect (for OAuth-based providers: Google, Microsoft)
- Just-In-Time (JIT) user provisioning from SSO assertions
- SSO enforcement mode (disable password login when SSO is active)
- Attribute mapping from IdP claims to AgencyOS user fields

#### AUTH-FR-004: Role-Based Access Control
**Priority:** P0 | **Traces to:** AUTH-005

The system SHALL implement RBAC with:
- Pre-defined roles: Super Admin, Owner, PM, Team Lead, Developer, Designer, Marketer, HR Manager, Finance Manager, Operations Manager, Client
- Custom role creation with granular permissions per module and action (View, Create, Edit, Delete, Manage, Export)
- Permission inheritance (Owner inherits PM permissions)
- Row-level security for multi-tenant data isolation
- Permission caching with immediate invalidation on role change
- API-level and UI-level permission enforcement

#### AUTH-FR-005: API Authentication
**Priority:** P0 | **Traces to:** AUTH-007

The system SHALL support API authentication via:
- API keys with configurable scopes and expiration
- OAuth 2.0 bearer tokens for third-party integrations
- HMAC signatures for webhook verification
- Rate limiting per API key (configurable, default: 1000 requests/minute)
- API key rotation without downtime

### 4.2 Module: Organization Management

#### ORG-FR-001: Organization Structure
**Priority:** P0 | **Traces to:** ORG-001, ORG-002, ORG-003

The system SHALL support:
- Single organization per installation (multi-org via white-label sub-agencies)
- Hierarchical departments with unlimited nesting depth
- Teams within departments with cross-department membership
- Organization chart visualization (interactive tree view)
- Custom fields on all organizational entities (text, number, date, dropdown, URL, email, checkbox)

#### ORG-FR-002: Configuration Management
**Priority:** P0 | **Traces to:** ORG-007, ORG-008, ORG-009

The system SHALL support configurable:
- Working hours per location (supporting different work weeks)
- Holiday calendar per location (recurring and one-time)
- Fiscal year definition (arbitrary start month)
- Default currency and additional currencies
- Date/time format preferences
- Notification delivery preferences per user (in-app, email, push)
- Branding (logo, colors, fonts, product name)

### 4.3 Module: Project Management

#### PROJ-FR-001: Project CRUD
**Priority:** P0 | **Traces to:** PROJ-001, PROJ-006, PROJ-009, PROJ-010

The system SHALL support:
- Project creation with: name, code (auto-generated), client, description, dates, budget, billing type (fixed/hourly/retainer), project manager, team, tags, custom fields
- Project statuses: Planning, Active, On Hold, Completed, Archived
- Project templates with: phases, milestones, task structures, role allocations
- Project cloning with selective element inclusion
- Project archival (read-only access, excluded from active dashboards)
- Minimum required fields: name and project manager

#### PROJ-FR-002: Project Views
**Priority:** P0 | **Traces to:** PROJ-002, PROJ-004, PROJ-011

The system SHALL provide the following project views:
- **Dashboard:** KPI widgets (progress, budget, hours, health), activity feed, team members
- **Gantt Chart:** Interactive timeline with task bars, dependency arrows, critical path highlighting, drag-to-reschedule, zoom levels (day/week/month/quarter)
- **Portfolio:** Multi-project grid with health indicators, budget status, timeline status, filtering by client/PM/status/tag
- All views MUST respect RBAC (users see only authorized projects)

#### PROJ-FR-003: Project Financial Tracking
**Priority:** P0 | **Traces to:** PROJ-005

The system SHALL track project financials:
- Budget definition (total or phased)
- Real-time burn rate calculation (hours x rates + expenses)
- Configurable threshold alerts (50%, 75%, 90%, 100% of budget)
- Budget vs. actual variance reporting
- Revenue tracking (invoiced vs. projected)
- Project profitability (revenue - costs) at any time

#### PROJ-FR-004: Project Risk Management
**Priority:** P1 | **Traces to:** PROJ-007

The system SHALL support:
- Risk register per project (description, probability 1-5, impact 1-5, mitigation, owner, status)
- Risk matrix visualization (probability x impact)
- AI-powered risk analysis (triggers: AUTH-FR-018)
- Risk status tracking (identified, mitigated, occurred, closed)

### 4.4 Module: Task Management

#### TASK-FR-001: Task CRUD
**Priority:** P0 | **Traces to:** TASK-001, TASK-004, TASK-012, TASK-014, TASK-015

The system SHALL support:
- Task creation with: title, description (rich text with Markdown), assignee(s), due date, priority (Low/Medium/High/Urgent), estimated hours, tags, parent task, project, phase
- Subtasks with unlimited nesting depth (recommended max: 3 levels)
- Checklists within tasks (ordered items with checkbox)
- File attachments (max 50MB per file, integrated with Document Management)
- Task watchers (receive notifications without being assignee)
- Recurring tasks (daily, weekly, biweekly, monthly, custom cron)
- Task templates for reusable task structures

#### TASK-FR-002: Task Views
**Priority:** P0 | **Traces to:** TASK-002, TASK-007, TASK-008, TASK-009

The system SHALL provide task views:
- **Kanban Board:** Configurable columns (status-based), drag-and-drop, WIP limits, swimlanes (by assignee/priority/project), card customization (visible fields)
- **List/Table View:** Sortable columns, inline editing, bulk actions (status, assignee, priority, due date), column customization
- **Calendar View:** Tasks on due dates, drag-to-reschedule, month/week/day toggles
- **My Tasks:** Aggregated view across all projects, grouped by project, overdue highlighting, "Today" and "This Week" filters

#### TASK-FR-003: Task Dependencies
**Priority:** P1 | **Traces to:** TASK-003

The system SHALL support task dependencies:
- Dependency types: Blocked By, Blocks
- Status enforcement: blocked tasks cannot move to "In Progress" until blockers are resolved
- Visual indicators on Kanban cards and list view
- Notification to blocked task assignee when blocker is resolved
- Circular dependency prevention

#### TASK-FR-004: Task Activity & Comments
**Priority:** P0 | **Traces to:** TASK-005

The system SHALL track:
- All field changes with: timestamp, user, old value, new value (auto-generated activity entries)
- User comments with rich text, @mentions, and file attachments
- @mention notifications (in-app and email per user preference)
- Activity feed combining comments and system changes in chronological order

### 4.5 Module: Client Management (CRM)

#### CRM-FR-001: Client & Contact Management
**Priority:** P0 | **Traces to:** CRM-001, CRM-004, CRM-006

The system SHALL support:
- Company profiles: name, industry, website, phone, email, address, billing details, account manager, custom fields
- Contacts under companies: name, title, email, phone, role type (decision maker, technical, billing)
- Communication log: manual entries (call, email, meeting) + automated (email integration)
- Notes with pinning and visibility control (internal/shared)
- Document attachment per client (contracts, briefs, etc.)
- Client search and filtering by any field

#### CRM-FR-002: Sales Pipeline
**Priority:** P0 | **Traces to:** CRM-002

The system SHALL support:
- Configurable pipeline stages (default: Lead, Qualified, Proposal, Negotiation, Won, Lost)
- Deal records: name, client, value, probability, expected close date, assigned salesperson, notes
- Kanban board for pipeline visualization
- Pipeline metrics: total value, weighted value, conversion rates, cycle time, win rate
- Deal stage history with timestamps

#### CRM-FR-003: Client Intelligence
**Priority:** P1 | **Traces to:** CRM-003, CRM-007

The system SHALL calculate:
- Client health score (0-100) based on: delivery timeliness, budget adherence, communication frequency, feedback sentiment, payment speed
- AI lead scoring (0-100) with confidence level and contributing factors
- Client segmentation by configurable criteria (industry, revenue, health, tags)

### 4.6 Module: Financial Management

#### FIN-FR-001: Invoicing
**Priority:** P0 | **Traces to:** FIN-001, FIN-007, FIN-008

The system SHALL support:
- Invoice creation with: client, line items (description, quantity, rate, tax, discount), payment terms, notes
- Import unbilled time entries from Time Tracking module
- Multi-currency invoicing with exchange rate lock at creation
- Tax management with configurable rules (inclusive/exclusive, by region)
- Recurring invoices (weekly, monthly, quarterly) with auto-send option
- Invoice statuses: Draft, Sent, Viewed, Partial, Paid, Overdue, Void
- Branded PDF generation with agency branding
- Email delivery with unique payment link
- Invoice numbering with configurable format (e.g., INV-2026-001)

#### FIN-FR-002: Expense Management
**Priority:** P0 | **Traces to:** FIN-002

The system SHALL support:
- Expense creation: amount, currency, category, date, project, client, receipt upload, description, billable/non-billable
- Approval workflow: Pending > Approved/Rejected
- Billable expense inclusion in invoices
- Category management (customizable)
- Receipt storage in Document Management

#### FIN-FR-003: Financial Reporting
**Priority:** P0 | **Traces to:** FIN-003, FIN-004, FIN-009, FIN-010

The system SHALL provide:
- P&L reports at: project, client, department, and agency levels
- Budget tracking with threshold alerts (configurable percentages)
- Revenue recognition (straight-line, percentage of completion, milestone-based)
- Accounts receivable aging (current, 1-30, 31-60, 61-90, 90+ days)
- Financial dashboard: revenue (MTD/QTD/YTD), outstanding invoices, cash flow forecast, profitability by project, expense breakdown
- Automated payment reminders for overdue invoices

### 4.7 Module: HR & People

#### HR-FR-001: Employee Management
**Priority:** P0 | **Traces to:** HR-001, HR-002, HR-003, HR-006

The system SHALL support:
- Employee profiles: personal info, job title, department, team, manager, start date, employment type, salary, emergency contacts, skills, custom fields
- Attendance tracking: clock in/out (manual or integrated), work hours calculation, overtime flagging
- Leave management: request/approve/reject workflow, leave types (annual, sick, personal, maternity/paternity, unpaid), balance tracking, calendar integration
- Employee directory: searchable, filterable by department/team/skill
- Onboarding checklists: auto-generated per role, multi-stakeholder tasks

#### HR-FR-002: Performance & Development
**Priority:** P1 | **Traces to:** HR-005, HR-007

The system SHALL support:
- Performance review cycles: self, manager, 360, and peer review types
- Review forms with customizable competencies and rating scales
- Historical review comparison
- Skill matrix: employees x skills with proficiency levels (1-5)
- Payroll data export (CSV format compatible with major payroll providers)

### 4.8 Module: Time Tracking

#### TIME-FR-001: Time Entry
**Priority:** P0 | **Traces to:** TIME-001, TIME-002, TIME-003

The system SHALL support:
- Manual time entry: project, task, date, start/end times or duration, description, billable toggle
- Timer-based tracking: start/stop button, global timer in header bar, auto-pause after configurable maximum
- Weekly timesheet grid: projects x days of week, quick-entry, totals
- Duration validation: warning for entries >12 hours
- Minimum granularity: 15 minutes (configurable: 5, 10, 15, 30, 60 minutes)

#### TIME-FR-002: Timesheet Workflow
**Priority:** P0 | **Traces to:** TIME-004, TIME-005

The system SHALL support:
- Timesheet submission (weekly): status flow Draft > Submitted > Approved/Rejected
- Manager approval interface: pending timesheets with breakdown, approve/reject per timesheet
- Utilization reports: billable hours / available hours per person, team averages, trend over time, target comparison
- Lock timesheets after approval (prevent edits without manager unlock)

### 4.9 Module: Resource Management

#### RES-FR-001: Capacity Planning
**Priority:** P0 | **Traces to:** RES-001, RES-002, RES-004

The system SHALL support:
- Capacity heatmap: team members x time, color-coded by allocation percentage
- Resource allocation: assign persons to projects with percentage or hours/week, date range, project role
- Over-allocation detection and conflict warning
- Skill-based filtering (find available people with specific skills)
- Skill matrix maintenance (employees x skills x proficiency level)
- Utilization forecasting based on current allocations

### 4.10 Module: Document Management

#### DOC-FR-001: File Management
**Priority:** P0 | **Traces to:** DOC-001, DOC-002, DOC-003

The system SHALL support:
- File upload via drag-and-drop and file picker (max file size: 500MB, configurable)
- Hierarchical folder structure within projects and global spaces
- Version control: upload new versions, view history, download/restore previous versions
- File metadata: auto-extracted (size, type, dimensions) + user-defined (tags, description)
- Search: by name, tags, content (text-based files), uploader
- Thumbnail generation for images and PDFs
- Document templates with variable placeholders (auto-filled from entity data)
- Storage backend: MinIO (S3-compatible API)

### 4.11 Module: Communication Hub

#### COMM-FR-001: Messaging
**Priority:** P0 | **Traces to:** COMM-001, COMM-002, COMM-003, COMM-004

The system SHALL support:
- Public and private channels with membership management
- Direct messages (1-on-1 and group)
- Threaded replies within channels
- Rich text messages with formatting, @mentions, emoji reactions
- File sharing with inline previews (images, PDFs)
- Organization-wide announcements with read receipts
- Real-time delivery via WebSocket
- Message search (full-text)
- Typing indicators and online presence

### 4.12 Module: Reporting & Analytics

#### RPT-FR-001: Dashboard & Reports
**Priority:** P0 | **Traces to:** RPT-001, RPT-002, RPT-004, RPT-005

The system SHALL support:
- Custom dashboard builder: drag-and-drop canvas, configurable widgets (charts, KPIs, tables, lists)
- Widget configuration: data source, metric, dimension, date range, chart type, filters
- Chart types: bar, line, pie, donut, area, scatter, heatmap, treemap, funnel
- Pre-built report library (20+ reports across all modules)
- Scheduled reports: frequency, recipients, format (PDF, Excel, CSV)
- Dashboard sharing with role-based data filtering
- Export: PDF, CSV, Excel for all reports and dashboards

### 4.13 Module: Software Development

#### SDEV-FR-001: Agile Development
**Priority:** P0 | **Traces to:** SDEV-001, SDEV-002, SDEV-004, SDEV-005

The system SHALL support:
- Sprint management: create, start, end sprints with goals and date ranges
- Sprint board: Kanban view with configurable columns (To Do, In Progress, Code Review, QA, Done)
- Product backlog: prioritized list of stories/tasks, drag-to-reorder, story point estimation
- Velocity tracking: chart showing points committed vs. completed per sprint, 3-sprint average
- Sprint burndown chart: ideal vs. actual work remaining
- Release management: version tracking, linking stories to releases, auto-generated release notes

#### SDEV-FR-002: Code Integration
**Priority:** P0 | **Traces to:** SDEV-003, SDEV-006, SDEV-007

The system SHALL support:
- Git integration (GitHub, GitLab, Bitbucket): OAuth connection
- Auto-linking: commits and PRs with task IDs in messages linked to tasks
- PR status display within task cards
- Auto-status-update: configurable rules (e.g., PR merged → task status = Done)
- Technical debt tracking: dedicated tag/type, severity, debt dashboard

### 4.14 Module: Marketing & Campaigns

#### MKT-FR-001: Campaign Management
**Priority:** P0 | **Traces to:** MKT-001, MKT-002, MKT-003, MKT-005

The system SHALL support:
- Campaign creation: name, client, type (SEO, PPC, Social, Email, Content), budget, dates, KPIs, team
- Content calendar: visual monthly/weekly view, content items plotted by publish date, color-coded by channel
- Campaign analytics: impressions, clicks, CTR, conversions, CPA, ROI (manual entry or via integration)
- Client marketing reports: branded PDF with AI-generated executive summary
- UTM parameter management for tracking links

### 4.15 Module: Creative & Design

#### CRTV-FR-001: Asset & Review Management
**Priority:** P1 | **Traces to:** CRTV-001, CRTV-002, CRTV-003

The system SHALL support:
- Digital asset library: organized by client/campaign/type, visual thumbnails, metadata extraction, tag suggestions
- Visual proofing: point annotations, area annotations, comment threads on specific locations, version comparison
- Approval workflows: multi-stage (e.g., Internal > Client > Final), approve/request changes/reject at each stage
- Asset versioning: side-by-side comparison between versions

### 4.16 Module: Client Portal

#### CP-FR-001: Client Access
**Priority:** P0 | **Traces to:** CP-001, CP-002, CP-003, CP-004

The system SHALL support:
- Branded client login (separate from internal login, using white-label branding)
- Client dashboard: active projects, progress, milestones, recent updates, action items
- Feedback and approval: comment on deliverables, annotate designs, approve/request changes
- File sharing: upload/download files, organized by project
- Invoice viewing: list with status, download PDF
- Data isolation: clients ONLY see data explicitly shared with them (not internal tasks, time, or communications)

### 4.17 Module: Gamification Engine

*(Detailed in Section 9)*

### 4.18 Module: AI Engine

*(Detailed in Section 8)*

### 4.19 Module: Audit & Compliance

*(Detailed in Section 10)*

### 4.20 Module: Integration Hub

#### INT-FR-001: Integration Framework
**Priority:** P0 | **Traces to:** INT-001, INT-002, INT-003, INT-004

The system SHALL support:
- Pre-built integrations (Phase 3): Slack, GitHub, GitLab, Bitbucket, Google Calendar, Google Drive, Stripe, QuickBooks, Xero, Jira (import), Asana (import), Monday.com (import), HubSpot (import), Microsoft Teams, Outlook
- Webhook system: outbound webhooks for 50+ event types, HMAC authentication, retry with exponential backoff, delivery logging
- REST API: versioned (v1), JWT authenticated, rate-limited, paginated, HATEOAS compliant, OpenAPI 3.0 documented
- GraphQL API: single endpoint, authentication, schema documentation, query depth limiting
- Custom integration builder (Phase 4): visual trigger → action interface, HTTP request configuration, response mapping

### 4.21 Extended Modules

#### EXT-FR-001: Knowledge Base
**Priority:** P1 | **Traces to:** KB-001, KB-002, KB-003

The system SHALL support hierarchical documentation with rich text editing, AI-powered search, version history, spaces/categories, and cross-referencing.

#### EXT-FR-002: Recruitment / ATS
**Priority:** P1 | **Traces to:** REC-001, REC-002, REC-003, REC-004

The system SHALL support job postings, applicant pipeline (Kanban stages), AI resume screening with match scoring, interview scheduling with calendar integration, and onboarding handoff.

#### EXT-FR-003: Contract Management
**Priority:** P1 | **Traces to:** CTR-001, CTR-002, CTR-003

The system SHALL support contract creation from templates, e-signature integration, lifecycle tracking, renewal/expiry alerts (30/60/90 days), and contract dashboard.

#### EXT-FR-004: Proposal / Estimate Builder
**Priority:** P1 | **Traces to:** PROP-001, PROP-002, PROP-003

The system SHALL support drag-and-drop proposal creation with blocks (cover, scope, pricing, team, terms), interactive web delivery, client accept/decline workflow, and proposal-to-project conversion.

#### EXT-FR-005: Quality Assurance
**Priority:** P1 | **Traces to:** QA-001, QA-002, QA-003, QA-004

The system SHALL support test case management, test suites, test plans linked to releases, test execution (pass/fail/blocked/skipped), bug tracking with severity levels, and QA dashboard with metrics.

#### EXT-FR-006: Customer Support / Ticketing
**Priority:** P1 | **Traces to:** SUP-001, SUP-002, SUP-003

The system SHALL support ticket creation (from portal and internal), SLA management with timer and escalation, agent assignment (auto and manual), CSAT surveys, and support analytics.

#### EXT-FR-007: OKR / Goal Management
**Priority:** P1 | **Traces to:** OKR-001, OKR-002, OKR-003, OKR-004

The system SHALL support objectives with key results (metric-based), goal cascading (company → department → team → individual), progress tracking with check-ins, alignment visualization, and AI goal suggestions.

#### EXT-FR-008: Workflow Automation
**Priority:** P1 | **Traces to:** WF-001, WF-002, WF-003, WF-004

The system SHALL support visual no-code workflow builder (trigger → condition → action), pre-built templates, approval chain configuration, scheduled automations (cron), cross-module triggers and actions, and execution logging.

#### EXT-FR-009: White-Label / Multi-Brand
**Priority:** P1 | **Traces to:** WL-001, WL-002, WL-003

The system SHALL support complete branding customization (logo, colors, fonts, product name, favicon), custom domain with SSL, sub-agency creation with isolated data and branding, and branded email templates.

#### EXT-FR-010: Inventory / Asset Management
**Priority:** P2 | **Traces to:** INV-001, INV-002, INV-003

The system SHALL support hardware asset tracking (type, serial, assignee, warranty), software license management (seats, renewal, cost), procurement workflow (request → approve → order → receive → assign), and depreciation tracking.

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements

#### NFR-PERF-001: Page Load Time
The system SHALL render interactive pages (Time to Interactive) within:
- **2 seconds** for the 95th percentile of requests on a standard connection (10 Mbps)
- **500ms** for subsequent navigations (client-side routing)
- **3 seconds** for complex dashboards with multiple data sources

#### NFR-PERF-002: API Response Time
The system SHALL respond to API requests within:
- **200ms** for simple CRUD operations (95th percentile)
- **500ms** for complex queries with aggregations (95th percentile)
- **3 seconds** for AI-powered features (95th percentile, excluding Gemini API latency)
- **5 seconds** for report generation (95th percentile)

#### NFR-PERF-003: Concurrent Users
The system SHALL support:
- **500 concurrent users** on recommended hardware (8 cores, 32GB RAM)
- **100 concurrent users** on minimum hardware (4 cores, 16GB RAM)
- **2,000+ concurrent users** with horizontal scaling (Kubernetes deployment)
- **50 concurrent WebSocket connections** per server instance minimum

#### NFR-PERF-004: Database Performance
The system SHALL maintain:
- **<50ms** average query execution time for indexed queries
- **<500ms** for complex analytical queries
- **<5 seconds** for materialized view refresh
- Connection pooling with maximum **100 connections** per server instance
- Query optimization monitoring with slow query logging (>1 second)

#### NFR-PERF-005: File Operations
The system SHALL support:
- File upload: up to **500MB** per file
- Upload speed: limited by network bandwidth, not application processing
- Thumbnail generation: **<5 seconds** for images up to 50MB
- File download: direct streaming from MinIO (no application buffering)

### 5.2 Scalability Requirements

#### NFR-SCALE-001: Horizontal Scaling
The system SHALL support horizontal scaling:
- Stateless application servers behind a load balancer
- Session data stored in Redis (shared across instances)
- File storage in MinIO (shared across instances)
- Database read replicas for read-heavy workloads (optional)
- Linear performance improvement with additional application instances

#### NFR-SCALE-002: Data Volume
The system SHALL handle:
- **1 million** tasks per organization without performance degradation
- **100,000** projects per organization
- **10,000** users per organization
- **50 million** audit log entries per year with efficient querying
- **1TB+** of file storage (limited by MinIO capacity)

### 5.3 Reliability Requirements

#### NFR-REL-001: Availability
The system SHALL achieve:
- **99.9% uptime** (maximum 8.76 hours downtime per year) excluding planned maintenance
- Planned maintenance windows: zero-downtime deployments using rolling updates
- Graceful degradation: if Gemini API is unavailable, all non-AI features continue functioning
- Automatic health checks and restart of failed services (Docker health checks)

#### NFR-REL-002: Data Integrity
The system SHALL ensure:
- ACID compliance for all database transactions
- Referential integrity enforced at the database level
- Optimistic locking for concurrent edits (prevents silent overwrites)
- Idempotent API operations (safe to retry failed requests)
- Point-in-time recovery via PostgreSQL WAL archiving

#### NFR-REL-003: Backup & Recovery
The system SHALL provide:
- Automated daily database backups (configurable schedule)
- Backup retention: configurable (default 30 days)
- Point-in-time recovery to any second within the retention period
- File storage backup (MinIO replication or rsync)
- Tested restore procedure with documented RTO: **<4 hours**, RPO: **<1 hour**

### 5.4 Security Requirements

*(Detailed in Section 11)*

### 5.5 Maintainability Requirements

#### NFR-MAINT-001: Code Quality
The system SHALL maintain:
- **100%** TypeScript strict mode (no `any` types in production code)
- **80%+** code coverage for unit tests
- **100%** coverage for critical paths (auth, finance, audit)
- ESLint and Prettier enforced via pre-commit hooks
- Automated CI pipeline with: lint, type check, unit tests, integration tests, build

#### NFR-MAINT-002: Documentation
The system SHALL provide:
- API documentation auto-generated from OpenAPI/GraphQL schema
- Architecture Decision Records (ADRs) for significant technical decisions
- Module README files with dependency maps and data flow
- Deployment and configuration documentation
- Runbook for common operational tasks

#### NFR-MAINT-003: Monitoring & Observability
The system SHALL support:
- Structured JSON logging with correlation IDs
- Health check endpoints (`/health`, `/ready`)
- Prometheus-compatible metrics endpoint (`/metrics`)
- Distributed tracing support (OpenTelemetry)
- Error tracking integration (Sentry-compatible)
- System health dashboard (CPU, memory, disk, connections, queues)

### 5.6 Usability Requirements

#### NFR-USE-001: Accessibility
The system SHALL comply with **WCAG 2.1 Level AA**:
- Keyboard navigation for all interactive elements
- Screen reader compatibility (ARIA labels)
- Color contrast ratio: minimum 4.5:1 for normal text, 3:1 for large text
- Focus indicators for all interactive elements
- Skip navigation links

#### NFR-USE-002: Internationalization
The system SHALL support:
- English (LTR) and Arabic (RTL) at launch
- i18n framework supporting unlimited additional languages
- RTL layout with proper mirroring of UI elements
- Locale-specific formatting: dates, numbers, currency
- Bidirectional text support in all text inputs

#### NFR-USE-003: Responsive Design
The system SHALL render correctly on:
- Desktop: 1280px+ width (primary target)
- Tablet: 768px-1279px (fully functional, responsive layout)
- Mobile: 320px-767px (core functionality accessible, simplified views)

### 5.7 Portability Requirements

#### NFR-PORT-001: Deployment Portability
The system SHALL run on:
- Any Linux distribution with Docker 24+ support
- Bare metal, virtual machines, and cloud infrastructure (AWS, GCP, Azure, DigitalOcean, etc.)
- ARM64 and AMD64 processor architectures
- Air-gapped environments (with pre-downloaded container images and offline AI fallback)

#### NFR-PORT-002: Data Portability
The system SHALL support:
- Full data export in standard formats (CSV, JSON)
- Database dump/restore via standard PostgreSQL tools
- File storage export via S3-compatible tools
- API access to all data for custom migration scripts

---

## 6. Data Model

### 6.1 Entity-Relationship Overview

The database consists of approximately **80+ tables** organized by module. Below are the core entities and their key relationships.

### 6.2 Core Entities

#### 6.2.1 Organization & Users

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Organization   │     │      User        │     │      Role        │
├──────────────────┤     ├──────────────────┤     ├──────────────────┤
│ id (PK)          │     │ id (PK)          │     │ id (PK)          │
│ name             │◄────│ organization_id  │     │ name             │
│ slug             │     │ email            │     │ permissions      │
│ logo_url         │     │ password_hash    │     │ is_system        │
│ industry         │     │ first_name       │     │ organization_id  │
│ timezone         │     │ last_name        │     │ created_at       │
│ currency         │     │ avatar_url       │     └──────────────────┘
│ fiscal_year_start│     │ role_id (FK)     │──────────────┘
│ settings (JSONB) │     │ department_id    │
│ created_at       │     │ status           │
│ updated_at       │     │ mfa_enabled      │
└──────────────────┘     │ last_login_at    │
                         │ created_at       │
                         │ updated_at       │
                         └──────────────────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
            ┌──────────┐ ┌──────────┐ ┌──────────┐
            │Department│ │   Team   │ │ Session  │
            ├──────────┤ ├──────────┤ ├──────────┤
            │ id       │ │ id       │ │ id       │
            │ name     │ │ name     │ │ user_id  │
            │ parent_id│ │ dept_id  │ │ token    │
            │ head_id  │ │ lead_id  │ │ device   │
            └──────────┘ └──────────┘ │ ip       │
                                      │ expires  │
                                      └──────────┘
```

#### 6.2.2 Projects & Tasks

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│    Project       │     │      Task        │     │   TimeEntry      │
├──────────────────┤     ├──────────────────┤     ├──────────────────┤
│ id (PK)          │     │ id (PK)          │     │ id (PK)          │
│ name             │◄────│ project_id (FK)  │◄────│ task_id (FK)     │
│ code             │     │ title            │     │ user_id (FK)     │
│ client_id (FK)   │     │ description      │     │ project_id (FK)  │
│ manager_id (FK)  │     │ status           │     │ date             │
│ status           │     │ priority         │     │ start_time       │
│ start_date       │     │ assignee_id (FK) │     │ end_time         │
│ end_date         │     │ parent_id (FK)   │     │ duration_minutes │
│ budget           │     │ due_date         │     │ description      │
│ billing_type     │     │ estimated_hours  │     │ is_billable      │
│ settings (JSONB) │     │ actual_hours     │     │ status           │
│ created_at       │     │ sort_order       │     │ approved_by      │
│ updated_at       │     │ created_at       │     │ created_at       │
└──────────────────┘     │ updated_at       │     └──────────────────┘
                         └──────────────────┘
```

#### 6.2.3 CRM & Finance

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│    Client        │     │    Invoice       │     │    Expense       │
├──────────────────┤     ├──────────────────┤     ├──────────────────┤
│ id (PK)          │     │ id (PK)          │     │ id (PK)          │
│ company_name     │◄────│ client_id (FK)   │     │ project_id (FK)  │
│ industry         │     │ number           │     │ user_id (FK)     │
│ website          │     │ status           │     │ amount           │
│ phone            │     │ issue_date       │     │ currency         │
│ email            │     │ due_date         │     │ category         │
│ address (JSONB)  │     │ subtotal         │     │ date             │
│ billing (JSONB)  │     │ tax_amount       │     │ receipt_url      │
│ account_mgr_id   │     │ total            │     │ description      │
│ health_score     │     │ currency         │     │ is_billable      │
│ tags             │     │ exchange_rate    │     │ status           │
│ custom_fields    │     │ paid_amount      │     │ approved_by      │
│ created_at       │     │ paid_at          │     │ created_at       │
└──────────────────┘     │ created_at       │     └──────────────────┘
                         └──────────────────┘
         │                                              
         ▼                                              
┌──────────────────┐     ┌──────────────────┐
│    Contact       │     │     Deal         │
├──────────────────┤     ├──────────────────┤
│ id (PK)          │     │ id (PK)          │
│ client_id (FK)   │     │ client_id (FK)   │
│ name             │     │ name             │
│ title            │     │ value            │
│ email            │     │ probability      │
│ phone            │     │ stage            │
│ role_type        │     │ expected_close   │
│ is_primary       │     │ assigned_to      │
└──────────────────┘     │ created_at       │
                         └──────────────────┘
```

#### 6.2.4 Gamification

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  PointTransaction│     │    Badge         │     │  UserBadge       │
├──────────────────┤     ├──────────────────┤     ├──────────────────┤
│ id (PK)          │     │ id (PK)          │     │ id (PK)          │
│ user_id (FK)     │     │ name             │     │ user_id (FK)     │
│ points           │     │ description      │     │ badge_id (FK)    │
│ action_type      │     │ icon_url         │     │ tier             │
│ entity_type      │     │ category         │     │ earned_at        │
│ entity_id        │     │ criteria (JSONB) │     │ progress         │
│ description      │     │ tiers (JSONB)    │     └──────────────────┘
│ created_at       │     │ created_at       │
└──────────────────┘     └──────────────────┘

┌──────────────────┐     ┌──────────────────┐
│   Leaderboard    │     │    Streak        │
├──────────────────┤     ├──────────────────┤
│ id (PK)          │     │ id (PK)          │
│ user_id (FK)     │     │ user_id (FK)     │
│ period           │     │ type             │
│ total_points     │     │ current_count    │
│ rank             │     │ longest_count    │
│ category         │     │ last_activity_at │
│ calculated_at    │     │ freeze_count     │
└──────────────────┘     └──────────────────┘
```

#### 6.2.5 Audit

```
┌────────────────────────────┐
│        AuditLog            │
├────────────────────────────┤
│ id (PK, UUID)              │
│ timestamp (TIMESTAMPTZ)    │
│ user_id (FK, nullable)     │
│ action (VARCHAR)           │
│ entity_type (VARCHAR)      │
│ entity_id (UUID)           │
│ old_value (JSONB)          │
│ new_value (JSONB)          │
│ ip_address (INET)          │
│ user_agent (TEXT)          │
│ session_id (UUID)          │
│ module (VARCHAR)           │
│ severity (VARCHAR)         │
│ metadata (JSONB)           │
│ checksum (VARCHAR)         │ ← SHA-256 of the entry for tamper detection
└────────────────────────────┘
  ↓ Append-only table
  ↓ No UPDATE or DELETE permissions
  ↓ Partitioned by month for performance
```

### 6.3 Database Design Principles

1. **UUID Primary Keys:** All tables use UUID v7 (time-sortable) as primary keys
2. **Timestamps:** All tables include `created_at` and `updated_at` (TIMESTAMPTZ)
3. **Soft Deletes:** Business entities use `deleted_at` (TIMESTAMPTZ, nullable) instead of hard deletes
4. **JSONB for Flexibility:** Settings, custom fields, and metadata use JSONB columns for schema-less data
5. **Indexing Strategy:** B-tree indexes on all foreign keys and commonly queried fields; GIN indexes on JSONB and full-text search columns
6. **Partitioning:** Audit logs partitioned by month; time entries partitioned by year
7. **Row-Level Security:** PostgreSQL RLS policies enforce tenant isolation for multi-org data (white-label sub-agencies)
8. **Enums:** Status fields use PostgreSQL enums for type safety and performance

### 6.4 Migration Strategy

- Prisma Migrate for schema versioning and migrations
- All migrations are forward-only (no down migrations in production)
- Data migrations are separate from schema migrations
- Zero-downtime migrations: additive changes first, then data migration, then constraint enforcement

---

## 7. API Design

### 7.1 REST API

#### 7.1.1 General Conventions

| Aspect | Convention |
|---|---|
| **Base URL** | `/api/v1/` |
| **Authentication** | `Authorization: Bearer <JWT>` or `X-API-Key: <key>` |
| **Content Type** | `application/json` |
| **Pagination** | Cursor-based: `?cursor=<id>&limit=50` (max 100) |
| **Filtering** | Query parameters: `?status=active&client_id=<uuid>` |
| **Sorting** | `?sort=created_at&order=desc` |
| **Error Format** | `{ "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }` |
| **HTTP Methods** | GET (read), POST (create), PUT (full update), PATCH (partial update), DELETE (soft delete) |
| **Status Codes** | 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 409 (Conflict), 422 (Validation Error), 429 (Rate Limited), 500 (Internal Error) |

#### 7.1.2 Core API Endpoints

```
# Authentication
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
POST   /api/v1/auth/mfa/enable
POST   /api/v1/auth/mfa/verify

# Users
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id
GET    /api/v1/users/me

# Organizations
GET    /api/v1/organization
PATCH  /api/v1/organization
GET    /api/v1/organization/departments
POST   /api/v1/organization/departments
GET    /api/v1/organization/teams
POST   /api/v1/organization/teams

# Projects
GET    /api/v1/projects
GET    /api/v1/projects/:id
POST   /api/v1/projects
PATCH  /api/v1/projects/:id
DELETE /api/v1/projects/:id
GET    /api/v1/projects/:id/tasks
GET    /api/v1/projects/:id/time-entries
GET    /api/v1/projects/:id/documents
GET    /api/v1/projects/:id/budget

# Tasks
GET    /api/v1/tasks
GET    /api/v1/tasks/:id
POST   /api/v1/tasks
PATCH  /api/v1/tasks/:id
DELETE /api/v1/tasks/:id
GET    /api/v1/tasks/:id/comments
POST   /api/v1/tasks/:id/comments
GET    /api/v1/tasks/:id/activity
PATCH  /api/v1/tasks/:id/status
GET    /api/v1/tasks/my-tasks

# Clients (CRM)
GET    /api/v1/clients
GET    /api/v1/clients/:id
POST   /api/v1/clients
PATCH  /api/v1/clients/:id
DELETE /api/v1/clients/:id
GET    /api/v1/clients/:id/contacts
POST   /api/v1/clients/:id/contacts
GET    /api/v1/clients/:id/projects
GET    /api/v1/clients/:id/invoices

# Deals
GET    /api/v1/deals
GET    /api/v1/deals/:id
POST   /api/v1/deals
PATCH  /api/v1/deals/:id
PATCH  /api/v1/deals/:id/stage

# Invoices
GET    /api/v1/invoices
GET    /api/v1/invoices/:id
POST   /api/v1/invoices
PATCH  /api/v1/invoices/:id
POST   /api/v1/invoices/:id/send
POST   /api/v1/invoices/:id/payments
GET    /api/v1/invoices/:id/pdf

# Time Entries
GET    /api/v1/time-entries
POST   /api/v1/time-entries
PATCH  /api/v1/time-entries/:id
DELETE /api/v1/time-entries/:id
POST   /api/v1/time-entries/timer/start
POST   /api/v1/time-entries/timer/stop
GET    /api/v1/timesheets/weekly
POST   /api/v1/timesheets/:id/submit
POST   /api/v1/timesheets/:id/approve
POST   /api/v1/timesheets/:id/reject

# HR
GET    /api/v1/employees
GET    /api/v1/employees/:id
POST   /api/v1/employees
PATCH  /api/v1/employees/:id
GET    /api/v1/leave-requests
POST   /api/v1/leave-requests
POST   /api/v1/leave-requests/:id/approve
POST   /api/v1/leave-requests/:id/reject
GET    /api/v1/attendance

# Resources
GET    /api/v1/resources/capacity
POST   /api/v1/resources/allocations
GET    /api/v1/resources/allocations
GET    /api/v1/resources/skills

# Gamification
GET    /api/v1/gamification/points
GET    /api/v1/gamification/badges
GET    /api/v1/gamification/leaderboards
GET    /api/v1/gamification/streaks
GET    /api/v1/gamification/challenges
POST   /api/v1/gamification/recognition

# AI
POST   /api/v1/ai/chat
POST   /api/v1/ai/suggest/task-assignee
POST   /api/v1/ai/suggest/schedule
POST   /api/v1/ai/analyze/project-risk
POST   /api/v1/ai/generate/content
POST   /api/v1/ai/generate/report
GET    /api/v1/ai/insights
GET    /api/v1/ai/governance

# Audit
GET    /api/v1/audit/logs
GET    /api/v1/audit/compliance
GET    /api/v1/audit/entity/:type/:id/history

# Reporting
GET    /api/v1/reports/:report_id
GET    /api/v1/reports/library
GET    /api/v1/dashboards
POST   /api/v1/dashboards
GET    /api/v1/dashboards/:id

# Integrations
GET    /api/v1/integrations
POST   /api/v1/integrations/:provider/connect
DELETE /api/v1/integrations/:provider/disconnect
GET    /api/v1/webhooks
POST   /api/v1/webhooks
DELETE /api/v1/webhooks/:id

# System Admin
GET    /api/v1/admin/health
GET    /api/v1/admin/modules
PATCH  /api/v1/admin/modules/:id
GET    /api/v1/admin/backups
POST   /api/v1/admin/backups
GET    /api/v1/admin/license
```

### 7.2 GraphQL API

#### 7.2.1 Schema Overview

```graphql
type Query {
  # Projects
  projects(filter: ProjectFilter, pagination: Pagination): ProjectConnection!
  project(id: ID!): Project
  
  # Tasks
  tasks(filter: TaskFilter, pagination: Pagination): TaskConnection!
  task(id: ID!): Task
  myTasks(filter: MyTaskFilter): [Task!]!
  
  # Clients
  clients(filter: ClientFilter, pagination: Pagination): ClientConnection!
  client(id: ID!): Client
  
  # Users
  users(filter: UserFilter): [User!]!
  me: User!
  
  # Gamification
  leaderboard(period: Period!, category: String): [LeaderboardEntry!]!
  myPoints: PointsSummary!
  myBadges: [UserBadge!]!
  
  # AI
  aiInsights(limit: Int): [AIInsight!]!
  
  # Reports
  report(id: ID!, filter: ReportFilter): ReportData!
}

type Mutation {
  # Tasks
  createTask(input: CreateTaskInput!): Task!
  updateTask(id: ID!, input: UpdateTaskInput!): Task!
  deleteTask(id: ID!): Boolean!
  
  # Projects
  createProject(input: CreateProjectInput!): Project!
  updateProject(id: ID!, input: UpdateProjectInput!): Project!
  
  # Time
  startTimer(taskId: ID!): TimeEntry!
  stopTimer(id: ID!): TimeEntry!
  
  # AI
  aiChat(message: String!, context: AIContext): AIResponse!
  aiSuggestAssignee(taskId: ID!): [AssigneeSuggestion!]!
  
  # Gamification
  giveRecognition(input: RecognitionInput!): Recognition!
}

type Subscription {
  # Real-time
  taskUpdated(projectId: ID!): Task!
  messageReceived(channelId: ID!): Message!
  notificationReceived: Notification!
}
```

### 7.3 API Rate Limiting

| Authentication Method | Rate Limit | Window |
|---|---|---|
| JWT (User session) | 500 requests | Per minute |
| API Key (Standard) | 1,000 requests | Per minute |
| API Key (Enterprise) | 5,000 requests | Per minute |
| Unauthenticated | 20 requests | Per minute |
| AI endpoints | 100 requests | Per minute |
| Webhook endpoints | 200 requests | Per minute |

Rate limit headers included in every response:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 984
X-RateLimit-Reset: 1706832000
```

### 7.4 API Versioning

- Version in URL path: `/api/v1/`, `/api/v2/`
- Breaking changes result in a new version
- Previous versions supported for minimum 12 months after deprecation announcement
- Sunset header included when a version is deprecated: `Sunset: Sat, 01 Jan 2028 00:00:00 GMT`

---

## 8. AI Engine Specification (Gemini Integration)

### 8.1 Architecture

```
                          ┌─────────────────┐
                          │   AI Gateway    │
                          │  (Rate Limiter, │
                          │   Auth, Cache)  │
                          └────────┬────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
            ┌───────v──────┐ ┌────v─────┐ ┌──────v──────┐
            │ Chat Service │ │Analytics │ │  Content    │
            │ (Conversational)│ │ Service │ │  Generator  │
            └───────┬──────┘ └────┬─────┘ └──────┬──────┘
                    │              │              │
            ┌───────v──────────────v──────────────v──────┐
            │              Context Builder               │
            │  (Assembles relevant data for AI prompts)  │
            │  - User permissions (RBAC filter)          │
            │  - Entity data (project, task, client)     │
            │  - Historical patterns                     │
            │  - Organization context                    │
            └───────────────────┬────────────────────────┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
            ┌───────v───┐ ┌────v────┐ ┌────v─────┐
            │  Gemini   │ │ Cache   │ │ Fallback │
            │  API      │ │ Layer   │ │ (OpenAI/ │
            │  (Primary)│ │ (Redis) │ │  Local)  │
            └───────────┘ └─────────┘ └──────────┘
```

### 8.2 AI Provider Abstraction

```typescript
interface AIProvider {
  chat(messages: ChatMessage[], options: AIOptions): Promise<AIResponse>;
  generateContent(prompt: string, options: ContentOptions): Promise<string>;
  analyzeData(data: AnalysisInput, options: AnalysisOptions): Promise<AnalysisResult>;
  embedText(text: string): Promise<number[]>;
}

class GeminiProvider implements AIProvider { /* Primary */ }
class OpenAIProvider implements AIProvider { /* Fallback */ }
class LocalProvider implements AIProvider { /* Offline fallback - basic rules only */ }
```

### 8.3 AI Capabilities Specification

#### 8.3.1 Conversational Assistant (AI-001)

| Aspect | Specification |
|---|---|
| **Model** | Gemini 1.5 Pro (for complex queries), Gemini 1.5 Flash (for simple queries) |
| **Context Window** | Up to 128K tokens |
| **Response Time** | <3 seconds (target), <5 seconds (acceptable) |
| **RBAC Enforcement** | Context Builder filters data based on user permissions before including in prompt |
| **Conversation History** | Last 20 messages retained per session, stored in Redis (1-hour TTL) |
| **Data Access** | Read-only access to: projects, tasks, time entries, clients, invoices, reports (per user permissions) |
| **Guardrails** | No PII exposure to AI API if configured; response sanitization; prompt injection prevention |

#### 8.3.2 Intelligent Task Assignment (AI-002)

**Input:**
- Task description, required skills, project context
- Team members: skills, availability, current workload, historical performance

**Algorithm:**
```
For each candidate:
  skill_match = score(required_skills, candidate_skills)  // 0-100
  availability = 1 - (current_allocation / capacity)       // 0-1
  performance = historical_completion_rate_similar_tasks    // 0-1
  cost_efficiency = budget_remaining / candidate_rate       // normalized
  
  fit_score = (skill_match * 0.35) + (availability * 0.30) + 
              (performance * 0.25) + (cost_efficiency * 0.10)
```

**Output:** Top 3 candidates with fit scores and reasoning

#### 8.3.3 Project Risk Prediction (AI-003)

**Input (weekly analysis):**
- Task completion rates vs. plan
- Budget burn rate
- Resource utilization trends
- Scope changes (new tasks added)
- Blocker duration
- Historical project data (similar projects)

**Model:** Gemini analyzes structured data with prompt:
```
Analyze this project's health data and predict risk level (0-100).
Consider: timeline adherence, budget utilization, team capacity,
scope changes, and blocker patterns. Compare with historical 
data from similar projects.
```

**Output:** Risk score (0-100), contributing factors, trend, recommended actions

#### 8.3.4 Anomaly Detection (AI-007)

**Monitored Domains:**

| Domain | Anomaly Types | Sensitivity |
|---|---|---|
| **Financial** | Unusual expenses, duplicate invoices, rate discrepancies | High |
| **Time Tracking** | Impossible hours (>16h/day), zero-activity periods, timesheet manipulation patterns | Medium |
| **Security** | Bulk data export, off-hours access, unusual geographic access | Critical |
| **Operational** | Sudden velocity drops, budget spikes, resource conflicts | Medium |

**Detection Methods:**
1. Statistical: Z-score analysis against 90-day rolling averages
2. Rule-based: Configurable thresholds (e.g., expense > 3x category average)
3. AI-enhanced: Gemini analysis for complex pattern detection
4. Peer comparison: Individual patterns compared against team norms

### 8.4 AI Cost Management

| Control | Implementation |
|---|---|
| **Budget Limits** | Configurable monthly token budget per organization |
| **Model Selection** | Auto-select cheaper models (Flash) for simple queries; Pro for complex |
| **Response Caching** | Cache identical queries (same parameters, same data) for 15 minutes |
| **Request Batching** | Batch multiple small requests into single API calls where possible |
| **BYOK Support** | Customer provides their own Gemini API key (cost on their account) |
| **Usage Dashboard** | Real-time token usage, cost tracking, per-feature breakdown |
| **Graceful Degradation** | When budget exhausted: disable non-critical AI, keep anomaly detection |

### 8.5 AI Safety & Governance

| Measure | Implementation |
|---|---|
| **Prompt Injection Prevention** | Input sanitization, system prompt isolation, output validation |
| **PII Protection** | Option to mask PII before sending to Gemini API (names → [PERSON_1]) |
| **Audit Logging** | Every AI request/response logged with: user, prompt (sanitized), response, tokens, model, latency |
| **Hallucination Mitigation** | AI responses cite data sources; "I don't know" trained; confidence scores |
| **Human-in-the-Loop** | Autonomous actions require confidence >85%; below that, suggest to human |
| **Bias Monitoring** | Monthly review of AI assignment suggestions for demographic bias |
| **Emergency Kill Switch** | Super Admin can disable all AI features instantly from admin panel |

---

## 9. Gamification Engine Specification

### 9.1 Points Economy

#### 9.1.1 Point Actions Configuration Schema

```typescript
interface PointAction {
  id: string;
  name: string;
  description: string;
  module: string;                    // e.g., "tasks", "time-tracking"
  trigger_event: string;             // e.g., "task.completed_on_time"
  points: number;                    // Points awarded
  category: PointCategory;           // productivity, quality, growth, etc.
  frequency_cap: {
    max_per_day: number | null;      // null = unlimited
    max_per_week: number | null;
    cooldown_seconds: number | null; // Minimum time between awards
  };
  conditions: {                      // Additional conditions for awarding
    min_task_estimated_hours?: number;  // Prevent gaming with trivial tasks
    requires_approval?: boolean;        // Points held until manager approves
    min_description_length?: number;    // Prevent empty-effort items
  };
  is_active: boolean;
  is_system: boolean;                // System actions cannot be deleted
}

type PointCategory = 
  | "productivity"    // Task completion, deadline adherence
  | "quality"         // Code review, client satisfaction
  | "compliance"      // Timesheet, policy adherence
  | "growth"          // Training, certifications
  | "leadership"      // Mentoring, team building
  | "innovation"      // Automation, improvement suggestions
  | "revenue"         // Sales, upselling
  | "collaboration";  // Peer help, knowledge sharing
```

#### 9.1.2 Default Point Actions

| Action | Points | Category | Frequency Cap |
|---|---|---|---|
| Complete task on time | 10 | productivity | 20/day |
| Complete task ahead of schedule | 15 | productivity | 10/day |
| Complete task (overdue) | 3 | productivity | 20/day |
| Submit timesheet on time | 5 | compliance | 1/week |
| Log time entry (per day logged) | 2 | compliance | 1/day |
| Receive positive client feedback | 25 | quality | 5/week |
| Close a deal | 50 | revenue | No cap |
| Write knowledge base article | 15 | collaboration | 3/day |
| Complete training course | 30 | growth | No cap |
| Pass code review (zero issues) | 15 | quality | 10/day |
| Mentor session completed | 20 | leadership | 3/day |
| Create workflow automation | 25 | innovation | 2/day |
| Complete sprint at 100% | 20 | productivity | 1/sprint |
| Deliver project under budget | 40 | productivity | No cap |
| Refer a hired candidate | 100 | collaboration | No cap |

### 9.2 Badge System

#### 9.2.1 Badge Schema

```typescript
interface Badge {
  id: string;
  name: string;
  description: string;
  icon_url: string;
  category: PointCategory;
  tiers: BadgeTier[];
  criteria: BadgeCriteria;
}

interface BadgeTier {
  level: "bronze" | "silver" | "gold";
  threshold: number;          // e.g., 10, 50, 100
  bonus_points: number;       // Points awarded when tier is earned
  icon_url: string;           // Tier-specific icon
}

interface BadgeCriteria {
  type: "count" | "streak" | "aggregate" | "composite";
  metric: string;             // e.g., "tasks_completed_early"
  period?: string;            // "all_time" | "quarterly" | "monthly"
}
```

### 9.3 Leaderboard Algorithm

```
Leaderboard Calculation (runs every 15 minutes):

1. Collect all point transactions for the selected period
2. Sum points per user, grouped by category
3. Apply decay factor for older periods: 
   - This week: 1.0x
   - Last week: 0.9x  
   - 2 weeks ago: 0.8x
   (Configurable; can be disabled for pure sum)
4. Rank users by total weighted points
5. Store in Redis sorted set for O(1) rank lookups
6. Calculate rank changes (new rank vs. previous period)
```

### 9.4 Anti-Gaming Measures

| Measure | Implementation |
|---|---|
| **Frequency Caps** | Maximum points per action per time period |
| **Minimum Effort Threshold** | Tasks must have >0.5 estimated hours to earn points |
| **Peer Validation** | Certain actions (e.g., mentoring) require recipient confirmation |
| **Diminishing Returns** | Same action type yields 50% points after 5th instance per day |
| **AI Pattern Detection** | Gemini analyzes point-earning patterns for suspicious activity |
| **Manager Override** | Managers can flag and reverse fraudulent points |
| **Cooldown Periods** | Minimum time between identical point-earning events |
| **Quality Gates** | Task completion points require QA/review pass (configurable) |

### 9.5 Privacy Controls

- Users can opt out of leaderboard visibility (points still accrue privately)
- Users can control badge visibility on their profile
- Users can hide gamification UI entirely (personal preference)
- No punitive mechanics (no point deductions for missing targets)
- No impact on performance reviews unless agency explicitly configures it

---

## 10. Audit & Compliance Specification

### 10.1 Audit Trail Architecture

#### 10.1.1 Event Capture

Every state-changing operation is captured:

```typescript
interface AuditEvent {
  id: string;                    // UUID v7
  timestamp: Date;               // Server UTC time
  user_id: string | null;        // null for system actions
  session_id: string | null;     // Links to auth session
  action: AuditAction;           // CREATE, UPDATE, DELETE, LOGIN, etc.
  module: string;                // "projects", "finance", "auth", etc.
  entity_type: string;           // "project", "invoice", "user", etc.
  entity_id: string;             // UUID of the affected entity
  old_value: object | null;      // Previous state (for updates)
  new_value: object | null;      // New state (for creates/updates)
  ip_address: string;            // Client IP
  user_agent: string;            // Browser/API client info
  severity: "info" | "warning" | "critical";
  metadata: object;              // Additional context
  checksum: string;              // SHA-256(all fields + previous checksum) for chain integrity
}

type AuditAction =
  | "CREATE" | "READ" | "UPDATE" | "DELETE"
  | "LOGIN" | "LOGOUT" | "LOGIN_FAILED"
  | "PERMISSION_CHANGE" | "PASSWORD_RESET"
  | "EXPORT" | "IMPORT" | "BULK_OPERATION"
  | "AI_QUERY" | "AI_ACTION"
  | "INTEGRATION_SYNC" | "WEBHOOK_FIRE"
  | "SYSTEM_CONFIG_CHANGE";
```

#### 10.1.2 Immutability Enforcement

```sql
-- PostgreSQL policy: Prevent UPDATE and DELETE on audit_logs
CREATE POLICY audit_immutable ON audit_logs
  FOR ALL
  USING (false)
  WITH CHECK (true);

-- Only INSERT is allowed via the application service account
-- Even Super Admin cannot modify audit entries via the application

-- Additional protection: checksum chain
-- Each entry's checksum = SHA-256(entry_data + previous_entry_checksum)
-- Breaking the chain = detectable tampering
```

#### 10.1.3 Retention & Archival

| Data Type | Minimum Retention | Archive Strategy |
|---|---|---|
| Security events (login, permission changes) | 7 years | Move to compressed archive table after 1 year |
| Financial events (invoices, payments, expenses) | 7 years | Move to compressed archive table after 2 years |
| Operational events (task changes, project updates) | 2 years | Move to compressed archive table after 6 months |
| AI events (queries, responses) | 1 year | Aggregate after 6 months (remove raw prompts) |

### 10.2 Compliance Controls

#### 10.2.1 SOC 2 Type II Controls

| Control | Implementation |
|---|---|
| **CC6.1: Logical Access** | RBAC, MFA, session management, API key scoping |
| **CC6.2: System Boundaries** | Network isolation, firewall rules, IP restrictions |
| **CC6.3: External Access** | API authentication, rate limiting, webhook HMAC |
| **CC7.1: Change Management** | Audit trail for config changes, approval workflows |
| **CC7.2: Monitoring** | Real-time alerting, anomaly detection, health dashboards |
| **CC8.1: Incident Response** | Security incident workflow, notification procedures |
| **CC9.1: Risk Management** | Risk register, AI-powered risk assessment |

#### 10.2.2 GDPR Controls

| GDPR Article | Implementation |
|---|---|
| **Art. 5: Data Minimization** | Configurable field-level data retention; automatic anonymization |
| **Art. 6: Lawful Processing** | Consent management; legitimate interest documentation |
| **Art. 7: Consent** | Explicit consent tracking; easy withdrawal |
| **Art. 15: Right of Access** | "Download My Data" feature; machine-readable export (JSON) |
| **Art. 16: Rectification** | Users can edit personal data; change history maintained |
| **Art. 17: Erasure** | "Delete My Account" workflow; cascade deletion; 30-day grace period |
| **Art. 20: Portability** | Standard format data export (CSV, JSON) |
| **Art. 25: Privacy by Design** | Default privacy settings; data encryption; access controls |
| **Art. 30: Processing Register** | Automated data processing inventory |
| **Art. 33: Breach Notification** | Breach detection alerts; 72-hour notification template |

---

## 11. Security Requirements

### 11.1 Authentication Security

| Requirement | Specification |
|---|---|
| **Password Hashing** | bcrypt with cost factor 12+ |
| **Password Policy** | Minimum 12 characters, uppercase, lowercase, number, special character |
| **Brute Force Protection** | Account lockout after 5 failed attempts (15-minute cooldown) |
| **Session Tokens** | JWT with 15-minute access token, 7-day refresh token with rotation |
| **Token Storage** | HTTP-only, Secure, SameSite=Strict cookies for web; encrypted storage for API |
| **MFA** | TOTP (RFC 6238) with 30-second step, 6-digit codes |
| **SSO** | SAML 2.0 and OIDC with certificate validation |

### 11.2 Data Security

| Requirement | Specification |
|---|---|
| **Encryption at Rest** | PostgreSQL TDE or filesystem encryption (customer-managed) |
| **Encryption in Transit** | TLS 1.2+ required for all connections |
| **File Encryption** | MinIO server-side encryption (AES-256) |
| **Database Connections** | SSL required for PostgreSQL connections |
| **Sensitive Fields** | PII fields encrypted at application layer (AES-256-GCM) in addition to TDE |
| **Key Management** | Encryption keys stored separately from data; rotatable via admin |
| **Backup Encryption** | All backups encrypted with separate keys |

### 11.3 Application Security (OWASP Top 10)

| Risk | Mitigation |
|---|---|
| **A01: Broken Access Control** | RBAC at API and UI level; row-level security in PostgreSQL; permission checks on every request |
| **A02: Cryptographic Failures** | TLS 1.2+; AES-256 encryption; bcrypt hashing; no sensitive data in logs |
| **A03: Injection** | Prisma ORM with parameterized queries; input sanitization; CSP headers |
| **A04: Insecure Design** | Threat modeling during design; security reviews; principle of least privilege |
| **A05: Security Misconfiguration** | Hardened Docker images; security scanning in CI; no default credentials |
| **A06: Vulnerable Components** | Automated dependency scanning (Dependabot/Snyk); regular updates |
| **A07: Auth Failures** | MFA, session management, brute force protection, secure password reset |
| **A08: Data Integrity Failures** | Signed audit logs; integrity checks; HMAC for webhooks |
| **A09: Logging Failures** | Comprehensive audit logging; structured logs; log integrity verification |
| **A10: SSRF** | URL validation; allowlist for external requests; no internal network access from user inputs |

### 11.4 Infrastructure Security

| Requirement | Specification |
|---|---|
| **Container Security** | Non-root containers; read-only filesystem; minimal base images (Alpine) |
| **Network Isolation** | Containers communicate via internal Docker network; only reverse proxy exposed |
| **Secrets Management** | Environment variables or Docker secrets; never in code or images |
| **Security Headers** | CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy |
| **CORS** | Strict origin validation; no wildcard in production |
| **Rate Limiting** | Per-endpoint rate limits; DDoS protection via reverse proxy |
| **Vulnerability Scanning** | Automated container image scanning in CI pipeline |

---

## 12. External Interface Requirements

### 12.1 User Interface Guidelines

#### 12.1.1 Design System

| Component | Specification |
|---|---|
| **Framework** | React (Next.js) with Tailwind CSS |
| **Component Library** | Custom design system based on Radix UI primitives |
| **Typography** | Inter (LTR), IBM Plex Sans Arabic (RTL/Arabic) |
| **Color System** | CSS custom properties supporting light/dark mode and white-label theming |
| **Iconography** | Lucide Icons (MIT licensed, consistent style) |
| **Spacing Scale** | 4px base unit (4, 8, 12, 16, 20, 24, 32, 40, 48, 64) |
| **Border Radius** | 4px (small), 8px (medium), 12px (large), 16px (card) |
| **Shadows** | 3 elevation levels: sm, md, lg |
| **Animations** | Framer Motion for transitions; 200ms default duration; reduced-motion support |
| **Dark Mode** | Supported via CSS custom properties toggle |

#### 12.1.2 Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│ Header: Logo, Search, AI Assistant, Notifications, User │
├───────┬─────────────────────────────────────────────────┤
│       │                                                 │
│ Side  │              Main Content Area                  │
│ bar   │                                                 │
│       │  ┌─────────────────────────────────────────┐    │
│ - Nav │  │  Page Header (Title + Actions)           │    │
│ - Mods│  ├─────────────────────────────────────────┤    │
│ - Quick│  │                                         │    │
│   Acts │  │  Content (Tables, Cards, Forms, etc.)  │    │
│       │  │                                         │    │
│       │  │                                         │    │
│       │  └─────────────────────────────────────────┘    │
│       │                                                 │
├───────┴─────────────────────────────────────────────────┤
│ Optional: Detail Panel (slides in from right)           │
└─────────────────────────────────────────────────────────┘
```

#### 12.1.3 Navigation Principles

- **Sidebar:** Always visible on desktop; collapsible on tablet/mobile
- **Module Navigation:** Only enabled modules appear in sidebar
- **Breadcrumbs:** Always present for context (Home > Projects > Project Alpha > Tasks)
- **Quick Actions:** Keyboard shortcut `Cmd/Ctrl + K` opens command palette
- **Search:** Global search accessible from header; searches across all modules
- **Contextual Actions:** Right-click menus and hover actions for power users

### 12.2 Hardware Interface Requirements

AgencyOS has no direct hardware interfaces. It runs as a web application accessed via standard web browsers. Peripheral devices (printers, cameras for receipts) are handled by the browser's native APIs.

### 12.3 Software Interface Requirements

| Interface | Protocol | Purpose |
|---|---|---|
| **PostgreSQL** | TCP/5432, libpq | Primary data storage |
| **Redis** | TCP/6379, RESP | Caching, sessions, pub/sub, job queue |
| **MinIO** | HTTP/9000, S3 API | File storage |
| **Gemini API** | HTTPS, REST | AI capabilities |
| **SMTP** | TCP/587 (TLS) | Email sending |
| **OAuth Providers** | HTTPS, OAuth 2.0 | SSO (Google, Microsoft, Okta) |
| **GitHub/GitLab** | HTTPS, REST/Webhooks | Code integration |
| **Slack** | HTTPS, REST/WebSocket | Communication integration |
| **Stripe** | HTTPS, REST | Payment processing |

### 12.4 Communication Interface Requirements

| Protocol | Usage |
|---|---|
| **HTTPS** | All client-server communication (TLS 1.2+ mandatory) |
| **WebSocket (WSS)** | Real-time updates: chat, notifications, live dashboards |
| **SSE** | Fallback for real-time when WebSocket is unavailable |
| **SMTP/TLS** | Outbound email delivery |
| **Webhook (HTTPS)** | Outbound event notifications to external systems |

---

## 13. Self-Hosted Deployment Specification

### 13.1 Deployment Architecture

#### 13.1.1 Single-Node Deployment (Docker Compose)

```yaml
# Simplified docker-compose.yml structure
services:
  app:
    image: agencyos/app:latest
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgresql://...
      REDIS_URL: redis://...
      MINIO_ENDPOINT: minio:9000
      GEMINI_API_KEY: ${GEMINI_API_KEY}
    depends_on: [postgres, redis, minio]
    
  worker:
    image: agencyos/app:latest
    command: ["node", "dist/worker.js"]
    environment: # Same as app
    depends_on: [postgres, redis]
    
  postgres:
    image: postgres:16-alpine
    volumes: ["pgdata:/var/lib/postgresql/data"]
    
  redis:
    image: redis:7-alpine
    volumes: ["redisdata:/data"]
    
  minio:
    image: minio/minio:latest
    volumes: ["miniodata:/data"]
    command: server /data --console-address ":9001"
    
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes: ["./nginx.conf:/etc/nginx/nginx.conf", "./certs:/etc/ssl"]
```

#### 13.1.2 Multi-Node Deployment (Kubernetes)

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                     │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  App Pod (1) │  │  App Pod (2) │  │  App Pod (3) │  │
│  │  Replicas:   │  │  Replicas:   │  │  Worker Pod  │  │
│  │  Auto-scale  │  │  Auto-scale  │  │  Replicas: 2 │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  PostgreSQL  │  │    Redis     │  │    MinIO     │  │
│  │  StatefulSet │  │  StatefulSet │  │  StatefulSet │  │
│  │  (Primary +  │  │  (Sentinel)  │  │  (Distributed)│ │
│  │   Replica)   │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │   Ingress    │  │  Cert-Manager│                     │
│  │  Controller  │  │  (Let's      │                     │
│  │  (Nginx/     │  │   Encrypt)   │                     │
│  │   Traefik)   │  │              │                     │
│  └──────────────┘  └──────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### 13.2 System Requirements

#### 13.2.1 Hardware Requirements

| Deployment Size | Users | CPU | RAM | Storage | Network |
|---|---|---|---|---|---|
| **Small** | 1-50 | 4 cores | 16GB | 100GB SSD | 100 Mbps |
| **Medium** | 50-200 | 8 cores | 32GB | 500GB SSD | 1 Gbps |
| **Large** | 200-500 | 16 cores | 64GB | 1TB SSD | 1 Gbps |
| **Enterprise** | 500+ | 32+ cores (K8s cluster) | 128GB+ | 2TB+ SSD | 10 Gbps |

#### 13.2.2 Software Requirements

| Software | Version | Required |
|---|---|---|
| Docker | 24+ | Yes (single-node) |
| Docker Compose | 2.20+ | Yes (single-node) |
| Kubernetes | 1.28+ | Yes (multi-node) |
| Helm | 3.12+ | Yes (multi-node) |
| Linux | Kernel 5.10+ | Yes |

### 13.3 Installation Process

#### 13.3.1 Quick Start (Docker Compose)

```bash
# 1. Download configuration
curl -sSL https://get.agencyos.com | bash

# 2. Configure environment
cp .env.example .env
# Edit .env with: database password, Gemini API key, SMTP settings, domain

# 3. Start services
docker compose up -d

# 4. Run initial setup
docker compose exec app npx agencyos setup

# 5. Access the platform
# Open https://your-domain.com
# Login with the admin credentials created during setup
```

#### 13.3.2 Installation Steps (Detailed)

1. **Prerequisites Check:** Verify Docker, system resources, network connectivity
2. **Configuration:** Generate `.env` file with all required variables
3. **SSL Setup:** Configure SSL certificates (Let's Encrypt or custom)
4. **Database Initialization:** Auto-create schema, run migrations, seed default data
5. **Admin Account Creation:** Interactive setup wizard for first admin user
6. **Organization Setup:** Company name, logo, timezone, currency
7. **Module Activation:** Select initial modules to enable
8. **Health Verification:** Automated post-install health check
9. **SMTP Verification:** Send test email to verify email delivery

### 13.4 Upgrade Process

```bash
# 1. Backup current state
docker compose exec app npx agencyos backup

# 2. Pull new images
docker compose pull

# 3. Apply upgrade (zero-downtime for app, brief pause for migrations)
docker compose up -d

# 4. Run migrations
docker compose exec app npx prisma migrate deploy

# 5. Verify
docker compose exec app npx agencyos health
```

**Upgrade Guarantees:**
- Backward-compatible database migrations (no data loss)
- Automatic pre-upgrade backup
- Rollback procedure documented for each release
- Changelog with breaking changes clearly marked
- Version compatibility matrix maintained

### 13.5 Backup & Disaster Recovery

| Component | Backup Method | Frequency | Retention |
|---|---|---|---|
| **PostgreSQL** | pg_dump (logical) + WAL archiving (PITR) | Daily dump + continuous WAL | 30 days (configurable) |
| **Redis** | RDB snapshots + AOF | Every 15 minutes | 7 days |
| **MinIO** | Bucket replication or rsync | Daily | 30 days |
| **Configuration** | .env file backup | On every change | Unlimited |

**Recovery Time Objectives:**
- **RTO (Recovery Time Objective):** <4 hours for full system restore
- **RPO (Recovery Point Objective):** <1 hour (with WAL archiving), <15 minutes (with streaming replication)

### 13.6 Monitoring & Alerting

| Component | Metrics | Tool |
|---|---|---|
| **Application** | Request rate, latency, errors, active users | Built-in `/metrics` endpoint (Prometheus format) |
| **Database** | Connections, query time, replication lag, disk usage | pg_stat_statements, built-in monitoring |
| **Redis** | Memory usage, hit rate, connected clients | Redis INFO command |
| **MinIO** | Storage usage, request rate, errors | MinIO metrics |
| **System** | CPU, memory, disk, network | Node Exporter (Prometheus) |
| **Containers** | Health status, restarts, resource usage | Docker/Kubernetes native |

**Built-in Alerting:**
- Email alerts for: high CPU (>90%), high memory (>90%), disk space low (<10%), database connection pool exhausted, application errors spike, failed backups, SSL certificate expiring
- All alerts configurable from Admin > System Health

---

## 14. Appendices

### Appendix A: Technology Stack Summary

| Layer | Technology | Version | License | Purpose |
|---|---|---|---|---|
| **Frontend Framework** | Next.js | 15+ | MIT | React-based full-stack framework |
| **Frontend Language** | TypeScript | 5.3+ | Apache 2.0 | Type-safe JavaScript |
| **UI Components** | Radix UI | Latest | MIT | Accessible, unstyled primitives |
| **Styling** | Tailwind CSS | 3.4+ | MIT | Utility-first CSS |
| **State Management** | Zustand | 4+ | MIT | Lightweight client state |
| **Data Fetching** | TanStack Query | 5+ | MIT | Server state management |
| **Charts** | Recharts | 2+ | MIT | Data visualization |
| **Rich Text** | TipTap | 2+ | MIT | WYSIWYG editor |
| **Backend Runtime** | Node.js | 22+ | MIT | JavaScript runtime |
| **API Layer** | tRPC + Express | Latest | MIT | Type-safe API + REST |
| **ORM** | Prisma | 5+ | Apache 2.0 | Database ORM |
| **Database** | PostgreSQL | 16+ | PostgreSQL | Primary data store |
| **Cache** | Redis | 7+ | BSD-3 | Caching, sessions, queues |
| **Job Queue** | BullMQ | 5+ | MIT | Background job processing |
| **Object Storage** | MinIO | Latest | AGPL-3.0 | S3-compatible file storage |
| **Real-Time** | Socket.io | 4+ | MIT | WebSocket abstraction |
| **AI** | Google Gemini API | Latest | Commercial | AI capabilities |
| **Search** | PostgreSQL FTS | -- | PostgreSQL | Full-text search |
| **Email** | Nodemailer | 6+ | MIT | SMTP email sending |
| **PDF** | Puppeteer / React PDF | Latest | Apache 2.0 | PDF generation |
| **Auth** | NextAuth.js | 5+ | ISC | Authentication framework |
| **Validation** | Zod | 3+ | MIT | Schema validation |
| **Testing** | Vitest + Playwright | Latest | MIT | Unit + E2E testing |
| **CI/CD** | GitHub Actions | -- | -- | Continuous integration |
| **Container** | Docker | 24+ | Apache 2.0 | Containerization |
| **Orchestration** | Kubernetes + Helm | 1.28+ | Apache 2.0 | Container orchestration |

### Appendix B: Glossary

| Term | Definition |
|---|---|
| **Bounded Context** | A module's clearly defined area of responsibility with its own data and logic |
| **Burn Rate** | Rate at which project budget is being consumed |
| **Critical Path** | The longest chain of dependent tasks determining minimum project duration |
| **Effective Bill Rate** | Actual revenue per hour worked (revenue / total hours) |
| **Event Sourcing** | Pattern where state changes are stored as a sequence of events |
| **Materialized View** | Pre-computed query result stored in the database for fast reads |
| **Modular Monolith** | Architecture where code is modular but deployed as a single unit |
| **Point-in-Time Recovery** | Ability to restore a database to any specific moment |
| **Row-Level Security** | Database-enforced access control at the individual row level |
| **Soft Delete** | Marking records as deleted without physically removing them |
| **Story Points** | Relative measure of effort/complexity for a user story |
| **Utilization Rate** | Percentage of available time spent on billable work |
| **Velocity** | Average story points completed per sprint |
| **WAL** | Write-Ahead Log — PostgreSQL's transaction log for recovery |
| **WIP Limit** | Maximum work items allowed in a Kanban column |

### Appendix C: Requirement Traceability Matrix

| Requirement ID | User Story | Module | Phase | Priority |
|---|---|---|---|---|
| AUTH-FR-001 | AUTH-001, AUTH-002 | Authentication | 0 | P0 |
| AUTH-FR-002 | AUTH-003 | Authentication | 0 | P0 |
| AUTH-FR-003 | AUTH-004 | Authentication | 1 | P1 |
| AUTH-FR-004 | AUTH-005 | Authentication | 0 | P0 |
| AUTH-FR-005 | AUTH-007 | Authentication | 1 | P0 |
| ORG-FR-001 | ORG-001 to ORG-004 | Organization | 1 | P0 |
| ORG-FR-002 | ORG-007 to ORG-009 | Organization | 1 | P0 |
| PROJ-FR-001 | PROJ-001 to PROJ-010 | Projects | 1 | P0 |
| PROJ-FR-002 | PROJ-002, PROJ-004, PROJ-011 | Projects | 1 | P0 |
| PROJ-FR-003 | PROJ-005 | Projects | 1 | P0 |
| PROJ-FR-004 | PROJ-007 | Projects | 2 | P1 |
| TASK-FR-001 | TASK-001 to TASK-015 | Tasks | 1 | P0 |
| TASK-FR-002 | TASK-002 to TASK-009 | Tasks | 1 | P0 |
| TASK-FR-003 | TASK-003 | Tasks | 1 | P1 |
| TASK-FR-004 | TASK-005 | Tasks | 1 | P0 |
| CRM-FR-001 | CRM-001 to CRM-006 | CRM | 1 | P0 |
| CRM-FR-002 | CRM-002 | CRM | 1 | P0 |
| CRM-FR-003 | CRM-003, CRM-007 | CRM | 2-3 | P1 |
| FIN-FR-001 | FIN-001 to FIN-008 | Finance | 1 | P0 |
| FIN-FR-002 | FIN-002 | Finance | 1 | P0 |
| FIN-FR-003 | FIN-003 to FIN-010 | Finance | 1 | P0 |
| HR-FR-001 | HR-001 to HR-006 | HR | 2 | P0 |
| HR-FR-002 | HR-005, HR-007 | HR | 2 | P1 |
| TIME-FR-001 | TIME-001 to TIME-003 | Time Tracking | 1 | P0 |
| TIME-FR-002 | TIME-004, TIME-005 | Time Tracking | 1 | P0 |
| RES-FR-001 | RES-001 to RES-004 | Resources | 2 | P0 |
| DOC-FR-001 | DOC-001 to DOC-003 | Documents | 1 | P0 |
| COMM-FR-001 | COMM-001 to COMM-004 | Communication | 2 | P0 |
| RPT-FR-001 | RPT-001 to RPT-005 | Reporting | 1 | P0 |
| SDEV-FR-001 | SDEV-001 to SDEV-005 | Software Dev | 2 | P0 |
| SDEV-FR-002 | SDEV-003, SDEV-006, SDEV-007 | Software Dev | 2 | P0 |
| MKT-FR-001 | MKT-001 to MKT-005 | Marketing | 2 | P0 |
| CRTV-FR-001 | CRTV-001 to CRTV-003 | Creative | 2 | P1 |
| CP-FR-001 | CP-001 to CP-004 | Client Portal | 2 | P0 |
| INT-FR-001 | INT-001 to INT-004 | Integrations | 3 | P0 |
| EXT-FR-001 | KB-001 to KB-003 | Knowledge Base | 4 | P1 |
| EXT-FR-002 | REC-001 to REC-004 | Recruitment | 4 | P1 |
| EXT-FR-003 | CTR-001 to CTR-003 | Contracts | 4 | P1 |
| EXT-FR-004 | PROP-001 to PROP-003 | Proposals | 4 | P1 |
| EXT-FR-005 | QA-001 to QA-004 | QA | 4 | P1 |
| EXT-FR-006 | SUP-001 to SUP-003 | Support | 4 | P1 |
| EXT-FR-007 | OKR-001 to OKR-004 | OKR | 4 | P1 |
| EXT-FR-008 | WF-001 to WF-004 | Automation | 4 | P1 |
| EXT-FR-009 | WL-001 to WL-003 | White-Label | 4 | P1 |
| EXT-FR-010 | INV-001 to INV-003 | Assets | 4 | P2 |

### Appendix D: Non-Functional Requirements Traceability

| NFR ID | Category | Requirement | Verification Method |
|---|---|---|---|
| NFR-PERF-001 | Performance | Page load <2s (p95) | Load testing (k6/Locust) |
| NFR-PERF-002 | Performance | API response <200ms CRUD, <500ms complex | Load testing |
| NFR-PERF-003 | Performance | 500 concurrent users on recommended hardware | Load testing |
| NFR-PERF-004 | Performance | Query execution <50ms (indexed) | Database monitoring |
| NFR-PERF-005 | Performance | File upload 500MB max | Integration testing |
| NFR-SCALE-001 | Scalability | Horizontal scaling via stateless app servers | Architecture review + stress testing |
| NFR-SCALE-002 | Scalability | 1M tasks, 100K projects, 10K users | Data volume testing |
| NFR-REL-001 | Reliability | 99.9% uptime | Monitoring + SLA tracking |
| NFR-REL-002 | Reliability | ACID compliance, optimistic locking | Unit tests + integration tests |
| NFR-REL-003 | Reliability | RTO <4 hours, RPO <1 hour | Disaster recovery drill |
| NFR-MAINT-001 | Maintainability | 80%+ code coverage | CI pipeline |
| NFR-MAINT-002 | Maintainability | Auto-generated API docs | CI pipeline + manual review |
| NFR-MAINT-003 | Maintainability | Structured logging, health checks, metrics | Monitoring setup verification |
| NFR-USE-001 | Usability | WCAG 2.1 AA compliance | Accessibility audit (axe-core) |
| NFR-USE-002 | Usability | English + Arabic (RTL) support | Manual testing |
| NFR-USE-003 | Usability | Responsive 320px-1920px+ | Cross-device testing |
| NFR-PORT-001 | Portability | Docker on any Linux, ARM64 + AMD64 | Multi-arch image builds |
| NFR-PORT-002 | Portability | Full data export in CSV/JSON | Integration testing |

### Appendix E: Open Questions & Future Considerations

| # | Question | Decision Needed By | Impact |
|---|---|---|---|
| 1 | Should we support PostgreSQL read replicas in the base Helm chart? | Phase 2 | Performance for large deployments |
| 2 | Should the GraphQL API support subscriptions for real-time data? | Phase 2 | Developer experience |
| 3 | Should we offer a managed SaaS option alongside self-hosted? | Phase 4 | Business model expansion |
| 4 | Should we build native mobile apps (React Native/Flutter)? | Post-Phase 4 | User experience |
| 5 | Should we open-source the core platform? | Phase 3 | Community growth vs. revenue |
| 6 | Should audit logs use a separate database for isolation? | Phase 3 | Security and performance |
| 7 | What is the migration path from competitor products (Jira, Asana)? | Phase 2 | Customer acquisition |
| 8 | Should we support Anthropic Claude as an AI alternative to Gemini? | Phase 3 | AI provider flexibility |
| 9 | Should gamification support team vs. team competitions? | Phase 3 | Engagement depth |
| 10 | Should the AI have write access (auto-create tasks, send emails)? | Phase 3 | Automation depth vs. safety |

---

## Document Approval

| Role | Name | Date | Signature |
|---|---|---|---|
| **Product Owner** | _________________ | __________ | _____________ |
| **Technical Lead** | _________________ | __________ | _____________ |
| **Security Lead** | _________________ | __________ | _____________ |
| **QA Lead** | _________________ | __________ | _____________ |
| **Stakeholder** | _________________ | __________ | _____________ |

---

*Document End — Software Requirements Specification v1.0*
*Related Documents: Business Analysis (docs/business-analysis.md), User Stories (docs/user-stories.md)*
