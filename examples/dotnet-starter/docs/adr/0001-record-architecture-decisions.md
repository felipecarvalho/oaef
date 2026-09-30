# 1. Record Architecture Decisions

Date: 2026-09-30

## Status

Accepted

## Context

We need to record architectural decisions made on `dotnet-starter`. Without structured records, the context and rationale behind structural choices become lost over time, leading to architectural erosion and repeated debates.

## Decision

We will use Architecture Decision Records (ADRs) as described by Michael Nygard. ADRs are numbered sequentially, stored in `docs/adr/`, written in Markdown, and committed directly to version control.

Any structural change, dependency shift, or cross-cutting pattern must be documented via an ADR approved in a Pull Request.

## Consequences

- Architectural context is preserved permanently within the codebase.
- Onboarding engineers and AI agents can understand the "why" behind historical technical decisions.
- Proposing major shifts requires documenting the trade-offs in an ADR.
