---
name: ralph-review-plan
description: Interactively review and improve a plan file before starting Ralph
tools: Read, Edit, AskUserQuestion
arguments:
  - name: plan_path
    description: Path to the plan file to review (e.g., .plans/my-feature.md)
    required: true
---

# Review Plan: $ARGUMENTS.plan_path

You are helping the user refine and improve their feature plan before they start autonomous development with Ralph.

## Your Goal

Review the plan file, identify gaps or ambiguities, and improve it through interactive conversation with the user. The plan should be clear enough that Ralph can generate actionable stories from it.

## Step 1: Read the Plan

First, read the plan file:

```
Read: $ARGUMENTS.plan_path
```

## Step 2: Initial Assessment

After reading, provide a brief assessment:

1. **Summary**: What is this feature about? (1-2 sentences)
2. **Clarity Score**: Rate 1-5 how clear and actionable the plan is
3. **Key Gaps**: List 2-4 things that need clarification

## Step 3: Interactive Questionnaire

**IMPORTANT**: Use the `AskUserQuestion` tool to present multiple questions AT ONCE as a form. Do NOT ask questions one-by-one in chat.

Based on your initial assessment, identify the 3-4 most important gaps and present them together:

```
AskUserQuestion({
  questions: [
    {
      question: "What's the scope of this feature?",
      header: "Scope",
      options: [
        { label: "MVP only", description: "Core functionality, nothing extra" },
        { label: "Full feature", description: "Complete implementation with polish" },
        { label: "Prototype", description: "Quick proof of concept" }
      ]
    },
    {
      question: "Are there existing patterns to follow?",
      header: "Patterns",
      options: [
        { label: "Yes - similar feature exists", description: "Point me to reference code" },
        { label: "Use project conventions", description: "Standard patterns from codebase" },
        { label: "New approach needed", description: "This is novel for the project" }
      ]
    },
    {
      question: "How should errors be handled?",
      header: "Errors",
      options: [
        { label: "Graceful fallback", description: "Continue with defaults" },
        { label: "Fail fast", description: "Stop and show error" },
        { label: "User choice", description: "Prompt user to decide" }
      ]
    },
    {
      question: "What's the testing strategy?",
      header: "Testing",
      options: [
        { label: "Unit tests", description: "Test individual functions" },
        { label: "Integration tests", description: "Test full flows" },
        { label: "Manual only", description: "No automated tests" }
      ]
    }
  ]
})
```

**Customize the questions** based on the specific gaps you identified in the plan. The example above is a template - adapt the questions to what's actually missing.

After receiving answers, you may ask ONE follow-up questionnaire if critical details are still missing.

## Step 4: Update the Plan

Once you've gathered enough information, propose updates to the plan:

1. Show the user what you'll add/change
2. Ask for confirmation
3. Use the Edit tool to update the plan file
4. Show the final result

## Step 5: Completion

When the plan is ready, tell the user:

```
Your plan has been updated and is ready for the next step.

You can now:
1. Click "Continue →" in Ralpher to generate stories from this plan
2. Or run: /ralph-new --from $ARGUMENTS.plan_path
```

## Guidelines

- Be concise - this is a refinement session, not a lecture
- Focus on gaps that would block story generation
- If the plan is already good, say so and suggest minor improvements
- Don't over-engineer - keep it practical
- Respect the user's original vision while improving clarity

## Example Interaction

**You**: I've read your plan for "CLI Pomodoro Timer". It's a solid start! Clarity: 3/5.

Key gaps:
- No mention of how timer state persists between sessions
- Unclear what "statistics" means specifically
- Missing error handling for interrupts (Ctrl+C)

Let me ask: When the user closes the terminal mid-session, should the pomodoro count as completed or abandoned?

**User**: Abandoned - only completed sessions count.

**You**: Got it. And for statistics - do you want daily/weekly/monthly views, or just a simple total count?

...and so on.
