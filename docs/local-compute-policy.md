# Local compute policy

This document records the local inference constraints for the Hermes-native OPC profile set.

The maintainer's Hermes Agent deployment uses local LM Studio / llama.cpp compute. The profile set must be designed for a personal local runtime, not for a concurrent serving cluster.

## Baseline

```text
runtime: Hermes Agent native profiles
backend: LM Studio / llama.cpp
model class: qwen3.6-35b-a3b
context target: 128K local context
serving slots: may expose multiple slots
OPC policy: one active profile call at a time
```

Even when the backend exposes multiple slots, OPC profile use must stay serialized.

## Hard rule

```text
Do not run multiple profile agents concurrently.
Do not dispatch multiple worker profiles in parallel.
Do not treat local slots as permission for parallel OPC execution.
```

OPC is role separation, not a parallel multi-agent swarm.

## Sequential profile flow

Allowed flow:

```text
secretary receives user message
secretary consults coordinator if task decomposition is needed
coordinator selects exactly one next profile
selected profile returns a compact result
secretary or coordinator decides the next step
```

Disallowed flow:

```text
secretary starts researcher + writer + builder concurrently
coordinator dispatches multiple workers in parallel
worker profiles run gateways by default
background tasks keep model slots occupied without user awareness
```

## Gateway constraint

Only `secretary` should be treated as the Lark-facing profile by default.

```text
Lark bot -> profile/secretary
```

Worker profiles should not run gateways by default.

Gateway, profile mutation, memory/session cleanup, Kanban reset, and Lark cutover require explicit maintainer approval.

## Context budget rule

The local context window is large, but not unlimited. The profile set must avoid transcript multiplication.

Risk pattern:

```text
secretary copies full Lark thread to coordinator
coordinator copies full thread to researcher/writer/builder
workers return long transcripts
secretary merges everything back into the long session
```

Preferred pattern:

```text
secretary creates compact summary
coordinator creates bounded handoff packet
worker returns compact result
secretary summarizes result and stores only what is useful
```

## Compression awareness

Hermes Agent may compress long sessions when context usage grows. The profile set should not wait for forced compression when a compact summary can be produced earlier.

Secretary should summarize proactively when:

```text
- the Lark-facing thread becomes long
- multiple handoffs have occurred
- worker outputs contain repeated context
- the user shifts to a new task scope
- old details are no longer needed for the next decision
```

Worker profiles should not return unnecessary long-form history.

## Handoff size policy

A handoff packet should include only:

```text
目的
必要背景摘要
目前已知來源
需要該 profile 處理的問題
輸出格式
限制條件
```

Do not include full raw transcripts unless explicitly required.

## Source handling

When external or retrieved context is needed, the requesting profile is responsible for deciding the minimum source bundle needed.

Examples:

```text
researcher: ask for evidence summary and source paths, not full wiki dumps
builder: ask for exact repo paths, command output, or official-doc snippets
writer: ask for verified conclusions and source status, not raw evidence volume
```

## Failure handling

If local compute appears busy, degraded, or context-heavy, profiles should prefer:

```text
- shorter handoff
- one next action
- explicit uncertainty
- asking secretary to continue later in the same sequential flow
```

They should not attempt to spawn additional parallel requests.

## Summary

```text
Local compute is shared personal capacity.
OPC profile calls are serialized.
Context must be compressed by design, not by accident.
Profile separation improves role clarity; it must not multiply token load unnecessarily.
```
