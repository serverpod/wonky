/// The built-in style guides of the assistant (suite 10 §7). Users pick one
/// per document (or their organization sets a default); *Apply style*
/// rewrites the document to match it and the other actions get it as
/// context. Users can duplicate a built-in guide to make their own.
library;

/// A built-in style guide.
class BuiltinStyleGuide {
  const BuiltinStyleGuide({
    required this.key,
    required this.name,
    required this.description,
    required this.markdown,
  });

  /// Stable key; the guide's ref is `builtin:<key>`.
  final String key;
  final String name;
  final String description;
  final String markdown;

  String get ref => 'builtin:$key';
}

abstract final class BuiltinStyleGuides {
  static const all = [
    developerDocs,
    technical,
    business,
    plainLanguage,
    marketing,
  ];

  static BuiltinStyleGuide? byKey(String key) {
    for (final g in all) {
      if (g.key == key) return g;
    }
    return null;
  }

  /// Developer documentation, adapted from the Serverpod writing style
  /// guide (github.com/serverpod/serverpod_docs, STYLE_GUIDE.md): the
  /// product-specific terminology and positioning are replaced by generic
  /// rules, and rules for code in prose are added.
  static const developerDocs = BuiltinStyleGuide(
    key: 'developer-docs',
    name: 'Developer documentation',
    description:
        'Clear, direct writing for software developers: concrete, no hype, '
        'consistent terms, sentence-case headings.',
    markdown: r'''
# Developer documentation

## Audience and voice

Write for hands-on engineers who build and ship software. Write like a senior engineer explaining something to another senior engineer.

- Be clear and direct. Lead with what the reader can do.
- Be specific and concrete: name the API, the command, the number.
- Avoid hype and vague claims. Say what something does instead of how great it is.
- Respect the reader's intelligence. Don't over-explain the basics.
- Acknowledge real tradeoffs and limitations without exaggerating them.
- Address the reader as "you". Use the present tense and the active voice.

Weak: The ultimate solution for modern apps.
Strong: Define your models once and get type-safe client code generated for you.

Weak: Managing infrastructure is a nightmare.
Strong: Running the database yourself means handling backups, upgrades, and failover.

## Words to avoid

These words add length without meaning, or sound like marketing in technical prose. Use the plain version.

| Avoid | Use instead |
| --- | --- |
| robust | reliable |
| seamless | smooth (or cut it) |
| powerful | cut it, or say what it does |
| intuitive | cut it, or say what it does |
| leverage | use |
| utilize | use |
| facilitate | help, allow |
| enables you to X | lets you X, you can X |
| simply, just, easily | cut them |

## Terminology

- Write product and project names exactly as their owners do, with the same capitalization.
- Use one term for one concept, and keep using it. Don't switch between synonyms ("endpoint", "route", "handler") for the same thing.
- Don't invent new labels for existing concepts unless there is a real technical difference.
- Define a term or acronym the first time it appears.

## Headings

- Use sentence case: capitalize the first word and proper nouns only.
- Make headings specific. Task headings start with a verb: "Deploy the server", not "Deployment".

Correct: Build your backend in Dart
Incorrect: Build Your Backend In Dart

## Lists and punctuation

- Always use the Oxford comma: "authentication, streaming, and an ORM".
- When list items are full sentences, end each with a period. When they are fragments, use no periods. Don't mix the two in one list.
- Number steps that must happen in order; use bullets otherwise. One action per step.
- Avoid em dashes in running text. Use a comma, parentheses, a colon, or a new sentence instead.

## Code in prose

- Format code, file names, commands, class and method names, and configuration keys as inline code: `pubspec.yaml`, `dart test`.
- Introduce every code block with a sentence that says what it does. Keep examples complete enough to run, and show the expected output when it helps.
- Don't start a sentence with inline code; rephrase it.
- Use placeholders that are obviously placeholders, such as `<your-project>`.

## Other tools and products

- Don't attack competitors or other tools. Avoid emotional or dismissive language.
- Compare through facts and tradeoffs: "If you need X, Y is a good fit."

## Calls to action

Use calm, confident, specific calls to action: "Get started with the tutorial.", "Read the API reference." Never use pressure such as "Don't miss out!" or "Act now!".
''',
  );

  static const technical = BuiltinStyleGuide(
    key: 'technical',
    name: 'Technical documentation',
    description:
        'Precise, task-oriented writing for manuals, how-tos, runbooks and '
        'specifications.',
    markdown: r'''
# Technical documentation

## Goal

Help the reader complete a task or understand a system correctly on the first read. Accuracy and clarity come before style.

## Voice

- Neutral, precise and impersonal in reference material; address the reader as "you" in instructions.
- Present tense and active voice: "The service retries the request", not "The request will be retried".
- No opinions, jokes or marketing language.

## Structure

- Start with a one-paragraph overview: what this is, who it is for, what the reader will achieve.
- State prerequisites before the steps.
- Use numbered steps for procedures, one action per step, starting with an imperative verb. Put the result of a step after it when it helps ("The dashboard opens.").
- Put reference information (options, parameters, limits) in tables.
- Use headings in sentence case that describe the content or task.

## Wording

- Use one term per concept and define it on first use. Expand acronyms the first time.
- Prefer short sentences (under 25 words) and short paragraphs (under 5 sentences).
- Be exact with numbers, units, versions and names. Write units with a space ("10 MB").
- Avoid vague words: "some", "various", "etc.", "simply", "just", "easily".
- Write warnings and notes only where they matter, and say what happens if the reader ignores them.

## Formatting

- Format UI labels in bold (**Save**), and code, commands, paths and values as inline code.
- Use the Oxford comma.
- Use lists for three or more parallel items.
''',
  );

  static const business = BuiltinStyleGuide(
    key: 'business',
    name: 'Business and professional',
    description:
        'Polished, courteous and concise writing for reports, proposals, '
        'memos and email.',
    markdown: r'''
# Business and professional

## Goal

Communicate decisions, facts and requests clearly to busy readers, and leave a professional impression.

## Voice

- Courteous, confident and direct. Neither stiff nor casual.
- Active voice; first person plural ("we") for the organization, "you" for the reader.
- No slang, emoji, exclamation marks or jokes. Avoid jargon and buzzwords ("synergy", "circle back", "move the needle").

## Structure

- Put the main point, decision or request first ("bottom line up front"), then the supporting detail.
- One idea per paragraph; keep paragraphs to three or four sentences.
- Use headings and bullet lists so the document can be skimmed.
- End with clear next steps: who does what by when.

## Wording

- Prefer short, plain words: "use" not "utilize", "help" not "facilitate", "about" not "with regard to".
- Be specific: give numbers, dates, owners and amounts.
- Remove filler and hedging ("I just wanted to", "it seems that", "basically").
- Keep a positive, solution-oriented tone when reporting problems.

## Formatting

- Headings in sentence case.
- Write dates unambiguously (7 November 2026) and use consistent number formats.
- Use the Oxford comma.
''',
  );

  static const plainLanguage = BuiltinStyleGuide(
    key: 'plain-language',
    name: 'Plain language',
    description:
        'Simple, everyday words and short sentences that anyone can '
        'understand on the first read.',
    markdown: r'''
# Plain language

## Goal

Anyone can read the text once, understand it and act on it. Write for a reader who is busy, possibly reading in a second language, and not an expert.

## Rules

- Use everyday words. Replace long or technical words with short, common ones ("use" not "utilize", "start" not "commence", "about" not "approximately").
- Keep sentences short: 15 to 20 words on average, one idea per sentence.
- Keep paragraphs short: one topic, at most four sentences.
- Use the active voice and say who does what: "We will send you a letter", not "A letter will be sent".
- Address the reader as "you" and the writer as "we".
- Explain technical terms and abbreviations, or avoid them.
- Put the most important information first.
- Use lists for steps, options and requirements.
- Use headings that say what the section is about; questions work well ("How do I apply?").
- Avoid double negatives, idioms and figures of speech.
- Be concrete: give examples, dates and numbers.
''',
  );

  static const marketing = BuiltinStyleGuide(
    key: 'marketing',
    name: 'Marketing and blog',
    description:
        'Engaging, benefit-led writing for blog posts, landing pages and '
        'newsletters, without hype.',
    markdown: r'''
# Marketing and blog

## Goal

Get the reader interested, show them why it matters to them, and make the next step obvious.

## Voice

- Warm, confident and conversational. Write like a knowledgeable friend, not a press release.
- Address the reader as "you". Contractions are fine.
- Enthusiasm comes from specifics, not superlatives. Avoid hype words ("revolutionary", "game-changing", "best-in-class") and empty claims.

## Structure

- Open with a hook: a problem the reader recognizes, a surprising fact or a short story.
- Lead with benefits (what the reader gets), then support them with features and facts.
- Use short paragraphs (one to three sentences), descriptive subheadings and lists so the text can be skimmed.
- Include concrete examples, numbers, quotes or customer stories.
- End with one clear call to action.

## Wording

- Headlines and subheadings in sentence case; keep headlines under about 70 characters and make them specific.
- Vary sentence length to keep a rhythm; keep most sentences short.
- Prefer strong verbs over adverbs.
- Keep claims honest and verifiable.
- Use the Oxford comma.
''',
  );
}
