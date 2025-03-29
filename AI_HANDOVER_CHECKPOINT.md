# MediSwitch Project - AI Handover Checkpoint

**Objective:** Continue development of the MediSwitch mobile application (Flutter) and its supporting backend (Django).

**Core Project Documents:**

1.  **`@/app_prompt.md`**: This file contains the **overall project vision, features, UI/UX guidelines, technical requirements, and monetization strategy**. It defines *what* needs to be built. **Read this first to understand the project goals.**
2.  **`@/mediswitch_plan.md`**: This file contains a **detailed, phased implementation plan** with specific tasks broken down into sub-tasks. It defines *how* the project should be built and tracks progress using `[ ]`, `[~]`, and `[x]` markers. **Refer to this file constantly to understand the current status and determine the next logical step.**

**Instructions for Continuing Development:**

1.  **Understand the Current State:** Before proceeding, thoroughly examine the entire project structure (frontend and backend), review the core documents (`app_prompt.md`, `mediswitch_plan.md`), and analyze the existing code to fully understand the current implementation status and architecture.
2.  **Follow the Plan:** Adhere strictly to the `@/mediswitch_plan.md`. Identify the next incomplete task (`[ ]` or `[~]`) in the logical sequence based on your analysis and implement it step-by-step.
3.  **Adopt the Methodology:** Follow the established development methodology:
    *   **Analyze:** Understand the task requirements from the plan and prompt.
    *   **Plan:** Break down the task into smaller, manageable steps. Use available tools (`read_file`, `list_files`, etc.) to gather necessary context before modifying code.
    *   **Implement:** Use the appropriate tools (`write_to_file`, `replace_in_file`, `execute_command`) one step at a time to implement the changes.
    *   **Validate:** After *every* tool use that modifies code or project state, **wait for the result** and meticulously check for any errors (compiler errors, linter warnings, runtime issues reported by the system). **CRITICAL: Do not proceed if errors exist.**
    *   **Fix:** Address and fix all reported errors immediately before moving to the next step.
    *   **Update Plan:** Once a task or sub-task is successfully completed **and verified to be error-free**, immediately update the `@/mediswitch_plan.md` file by changing the corresponding marker to `[x]`.
    *   **Iterate:** Proceed to the next logical task based on the plan.
4.  **Ask Before Deciding:** **Do not make assumptions or decisions.** If a task is ambiguous, requires choosing between options (like library choices, implementation details not specified in the plan), or if you are unsure about the next step, **you MUST ask for clarification** using the `ask_followup_question` tool before proceeding. Follow the user's direction.
5.  **Use Tools Correctly:** Execute file operations, commands, and other actions using the available tools one step at a time, waiting for confirmation after each tool use. Pay close attention to file paths and command syntax.
6.  **Refer to Core Documents:** Constantly refer back to `@/app_prompt.md` for feature requirements and `@/mediswitch_plan.md` for implementation details and status.

**Your First Task:**

*   Analyze the project state and the `@/mediswitch_plan.md` to determine the most logical next task to implement according to the plan and the established methodology. Propose this next step for user confirmation.
