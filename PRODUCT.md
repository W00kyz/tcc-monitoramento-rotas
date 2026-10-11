# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Primary: the manager (gestora/gestor) of the Prefeitura Universitária (PU) at UFCG, working at a desktop in the office. They plan routes, follow execution live, handle alerts, and produce reports to inspect outsourced contracts. Use is daily and prolonged.

Other roles that exist in the system (from the requirements document): the system administrator (users, access profiles, parameters such as check-in tolerance radius, audit logs) and the field worker (outsourced company staff, mobile app only, out of scope for the dashboard design work).

## Product Purpose

A dashboard plus mobile app that monitors how outsourced services (cleaning first; maintenance, gardening, pest control later) are executed on the UFCG campus. Field workers register presence by scanning QR Codes fixed on building floors, cross-checked with GPS, and attach evidence (photos, messages). Managers follow routes, alerts and reports in the web dashboard. Success: transparency, efficiency, and auditable proof that contracted services were delivered. Built as a TCC (final undergraduate project), with a pilot phase (LGPD hardening in etapa 11).

## Positioning

Check-in proof comes from signed QR Codes crossed with GPS, with offline execution and later sync, and the data model is service-type-agnostic. This replaces a mostly manual follow-up process with verifiable, per-point evidence.

## Operating Context

Manager sits at a desktop with a browser, watching a live board of routes and worker positions on an offline-capable map (OSM, PMTiles). Daily route assignment, emergency substitution and reassignment of points, one-off event routes, dynamic checklist forms per service type, alerts and notifications, historical reports with filters and export. Seed users: admin, gestora, field worker.

## Capabilities and Constraints

- 53 functional and 22 non-functional requirements (`docs/requisitos/Documento de Requisitos.pdf`).
- User-facing text in pt-BR (RNF02); code in English.
- Dashboard overview must load within 5 seconds (RNF05); must work correctly across the supported browsers (RNF15).
- LGPD adherence, geolocation only during working hours, audit trail of sensitive operations (RNF10-12).
- Stack: React 19, TypeScript, Vite, Tailwind, shadcn/Radix, Leaflet; API client generated from OpenAPI. Backend FastAPI/PostgreSQL; mobile Flutter (Android now, iOS 13+ required by RNF14).
- Mobile app is out of scope for Impeccable work; only the dashboard is.

## Brand Commitments

No UFCG/PU institutional identity is imposed: the dashboard has its own identity. Existing typography in the code is IBM Plex Sans/Mono, recorded as incumbent evidence, not a binding choice.

## Evidence on Hand

Real requirements document, specs per etapa in `docs/specs/`, and a working dashboard (`dashboard/`) with seed data. No testimonials, customer metrics or institutional brand assets exist; do not fabricate them.

## Product Principles

- Auditability first: every status shown can be traced to evidence (check-in, GPS, photo, form answer).
- Live operations over decoration: the manager must see what is wrong now and act without hunting.
- Generic by design: nothing assumes cleaning is the only service type.
- Privacy by default: show only the personal data the task needs (LGPD).
- Portuguese-first and plain: terminology the PU staff already uses.

## Accessibility & Inclusion

WCAG 2.1 AA as the minimum standard for the dashboard. pt-BR only. (RNF01, sunlight legibility, applies to the mobile app.)
