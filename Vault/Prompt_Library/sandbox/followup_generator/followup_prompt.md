# Follow-up Message Generator (Minimal Working Template)

## Instructions
Compose a short, friendly follow-up message to {{recipient}} from {{sender}}.
Context about the prior thread is in {{context}}.
It has been {{last_contact_days}} days since the last contact.

- Keep it human and concise (80–150 words).
- Include a clear nudge or next step (question, micro-CTA, or time proposal).
- Be polite; avoid pressure.
- If the context includes a specific request, acknowledge it first.
- Offer a graceful out if they’re not the right person.

## Output format
Return only the message body (no markdown headings, no extra labels).
Sign off as {{sender}}.

## Style guardrails
- Warm, professional, plain language.
- No absolutes or guarantees; helpful suggestions only.
- No personal data beyond what’s already in {{context}}.

<!-- INPUT CONTRACT (required by runner – do not remove) -->
- Recipient: {{recipient}}
- Sender: {{sender}}
- Days since last contact: {{last_contact_days}}
- Context: {{context}}
