# Process

- Check db/schema.rb when starting a new session to understand current DB structure.
- Focus on easy to understand and performant code, that foolows best practices.
- Always trigger the agent-code-reviewer agent after any task completion.
- Trigger `rubocop -a` and `bin/rails test` after task completion to ensure code quality and correctness.

# Testing

- Use system tests for major/important user flows.

# UI/UX

- The app will mainly be used on mobile. Ensure responsive design and usability on small screens.
- Autofocus input fields where appropriate for better user experience.
- Use clear and concise labels and placeholders in forms.
- Avoid basic text links for actions, use buttons instead as this will be used on mobile.

## Button Design System

All action buttons must have min 44px touch targets for mobile accessibility.

| Type | Use case | Tailwind classes |
|------|----------|------------------|
| **Primary** | Main action (Submit, Start, Join) | `px-6 py-3 bg-vermillion text-white font-medium rounded-lg hover:bg-vermillion-dark transition-colors` |
| **Secondary outline** | Important secondary actions | `px-4 py-2 border border-vermillion text-vermillion text-sm font-medium rounded-lg hover:bg-vermillion hover:text-white transition-colors` |
| **Neutral outline** | Less prominent actions | `px-4 py-2 border border-ink-muted text-ink-muted text-sm font-medium rounded-lg hover:border-ink hover:text-ink transition-colors` |
| **Destructive hint** | Neutral buttons that become destructive on hover | `px-4 py-2 border border-ink-muted text-ink-muted text-sm font-medium rounded-lg hover:border-vermillion hover:text-vermillion transition-colors` |

**Guidelines:**
- Primary buttons: One per section/form, for THE main action
- Secondary outline (vermillion): For important actions like "Avsluta röstning", "Föreslå bok"
- Neutral outline: For less prominent actions like "Byt bok", "Ta bort från kö"
- Destructive hint: For actions like "Ta bort", "Lämna klubben" that should warn on hover
- Navigation links (to other pages) can remain as text links

## Form Styles

Use these CSS classes for form inputs (defined in `app/assets/tailwind/application.css`):

| Class | Use case |
|-------|----------|
| `form-input` | Text inputs, textareas, email/password fields |
| `form-select` | Dropdown selects (includes custom arrow) |
| `form-input--sage` | Sage-colored focus state (use for discussion questions) |

**Features:**
- White background with `cream-dark` border for contrast
- 16px font size prevents iOS zoom on focus
- Vermillion focus ring (sage variant available)
- Proper padding for touch targets

**Labels:** `class="block text-sm font-medium text-ink-muted mb-2"`

## Editable Card Pattern

For multi-line editable items with actions (reorder, delete), use this card pattern:

```erb
<div class="bg-white rounded-lg border border-cream-dark overflow-hidden">
  <%= text_area_tag "name[]", value,
      rows: 3,
      placeholder: "...",
      class: "w-full px-4 py-3 text-base border-0 focus:outline-none focus:ring-0 resize-none" %>
  <div class="flex items-center justify-between px-2 py-1.5 bg-cream/30 border-t border-cream">
    <div class="drag-handle flex items-center gap-1 px-2 py-1 cursor-grab text-ink-muted/60 hover:text-ink-muted">
      <!-- drag icon + label -->
    </div>
    <button class="flex items-center gap-1 px-2 py-1 text-ink-muted/60 hover:text-vermillion">
      <!-- remove icon + label -->
    </button>
  </div>
</div>
```

**Use for:** Discussion questions, notes, any list of editable text items with actions.
