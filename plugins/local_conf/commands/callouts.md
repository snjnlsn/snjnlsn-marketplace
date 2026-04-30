---
description: Capture session findings as callouts in the current session's handoff
---

Use the `handle-callouts` skill to capture a finding as a properly-formatted callout (discovery, decision, caveat, gotcha, lesson learned, known issue, complexity, or edge case) in the current session's handoff.

If the user passed arguments after `/callouts`, treat them as the content or instruction (e.g., "save the JWT thing we just found as a discovery"). Otherwise, ask the user what they'd like to capture.
