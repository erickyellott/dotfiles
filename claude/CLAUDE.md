# Preferences

## Workflow

* For big system designs, walk through the design at a high level with me *first*,
  before writing any plan files or getting into granular details.
  Explain the core problem in plain language with basic examples, lay out the
  handful of real options and their tradeoffs. Only once we've agreed should you move to a plan and specifics.
* For large changes, write a plan to a md file first, in the plans directory for me to review. 
    * Number them like 01-foo.md. 
    * Let me annotate the plan and iterate with you. 
    * Confirm with me before making changes. 
    * Add a todo list to the bottom of the plan file to keep track of work. 
    * Break very large work into phases. Check things off the list as you complete them. 
      After completing a phase, pause and let me review your work. 
    * After all phases are done, ask me if I want a walkthrough of the changes.
* Don't write git commits.
* Don't run tests unless instructed.
* Never include or mention rollout or deployment sections in plans, unless we need to do a blue/green 
  or special case migration.

## Model delegation

* When using Opus or higher, delegate appropriate work to Sonnet.
* Keep on Opus (do it yourself, don't delegate): 
  * Architecture and design
  * Ambiguous or judgment-heavy changes
  * Security-sensitive code
  * Final review/integration of delegated work.
* Prefer batching independent delegated tasks into concurrent subagents.

## Style

* Don't add unnecessary comments for obvious things. Only add them when useful.
* Be concise, unless I'm learning something new.
* When writing md files, linewrap at 80.
