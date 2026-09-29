---
name: elixir-research
description: Use when researching Elixir ecosystem conventions, system design, architecture, implementation approaches, or dependency choices. Applies to open design questions about Elixir, OTP, Phoenix, and related tools. Does not apply to API syntax or documentation lookup alone.
---

# Elixir Research

Use [Elixir Forum](https://elixirforum.com/) as a guiding resource when deciding
how to build a system in the Elixir ecosystem. Research current practices before
committing to an architecture or dependency.

## Choose the research path

- Use this skill for questions such as how to structure a system, which OTP
  pattern fits a requirement, or which dependency the community uses for a task.
- Use Context7 for specific API behavior, configuration, syntax, and version
  documentation. Follow the project's documentation lookup rules.
- When a task needs both, use forum research to identify suitable approaches,
  then use documentation to verify the proposed implementation.

## Research the decision

1. Identify the decision and the project's constraints. Include relevant runtime
   versions, existing dependencies, deployment needs, and operational requirements.
2. Search Elixir Forum with the problem and candidate approaches. Use forum
   search or web queries scoped to `site:elixirforum.com`. Start with recent
   discussions, usually from the last one to two years. Widen the date range
   when recent evidence is limited or older threads explain a durable principle.
3. Read the relevant posts and follow-up replies. Check individual post dates
   and versions; a recent reply does not make every recommendation in an old
   thread current. Look for later corrections, replacements, and changed advice.
4. Compare the reasons behind recommendations. Give weight to maintainer
   explanations and reports of production use with constraints like the
   project's. Recency helps rank evidence, but relevance and technical support
   still matter. A new announcement alone does not establish common practice.
5. Verify shortlisted dependencies through current official documentation,
   release notes, and maintenance information. Use Context7 for documentation
   lookup. Check compatibility and support for the required behavior before
   recommending an implementation. Read dependency source only when the docs
   leave a material question unresolved.

## Present the findings

Recommend an approach and explain why it fits the project. Include meaningful
alternatives and their tradeoffs when they affect the decision. Link the forum
threads or specific posts that guided the recommendation, with their dates, and
link the official sources used to verify technical claims.

Separate community practice, documented guarantees, and your own inference.
Describe tooling as an ecosystem convention only when multiple independent
sources support that conclusion. Report disagreement or limited evidence
directly. If forum access fails, state that limitation and use available primary
sources without claiming that forum research was completed.
