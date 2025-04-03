tml # MediSwitch Project - AI Handover Checkpoint

**Objective:** Continue development of the MediSwitch mobile application (Flutter) and its supporting backend (Django).

**Core Project Documents:**

1.  **`@/app_prompt.md`**: Contains the **overall project vision, features, UI/UX guidelines, technical requirements, and monetization strategy**. Defines *what* needs to be built. **Study this VERY carefully.**
2.  **`@/mediswitch_plan.md`**: Contains a **detailed, phased implementation plan** with specific tasks. Defines *how* the project should be built and tracks progress. **Refer to this constantly and adhere strictly to determine the next step.**
3.  **`@/env.md`**: Details the **development environment setup** (versions, paths). **Ensure your environment is compatible.**

**Instructions for Continuing Development:**
 
1.  **Understand the Current State:**
    a.  **Initial Full Scan:** Before proceeding, **read ALL files** in the workspace to get a complete overview.
    b.  **Analyze Structure & Code:** Thoroughly examine the entire project structure (frontend and backend) and analyze existing code.
    c.  **Visualize Structure:** Draw or mentally map out the project's component structure and data flow.
    d.  **Study Core Documents:** **VERY CAREFULLY** review the core documents (`app_prompt.md`, `mediswitch_plan.md`, `env.md`) to fully understand the goals, plan, status, and environment.
2.  **Follow the Plan:** Adhere **strictly** to the `@/mediswitch_plan.md`. Identify the next incomplete task (`[ ]` or `[~]`) in the logical sequence based on your analysis and implement it step-by-step.
3.  **Adopt the Methodology:** Follow the established development methodology:
    *   **Analyze:** Understand the task requirements from the plan and prompt.
    *   **Plan:** Break down the task into smaller, manageable steps. Use available tools (`read_file`, `list_files`, etc.) to gather necessary context before modifying code.
    *   **Implement:** Use the appropriate tools (`write_to_file`, `apply_diff`, `execute_command`) one step at a time to implement the changes.
    *   **Validate:** After *every* tool use that modifies code or project state, **wait for the result** and meticulously check for any errors (compiler errors, linter warnings, runtime issues reported by the system). **CRITICAL: Do not proceed if errors exist.**
    *   **Fix:** Address and fix all reported errors immediately before moving to the next step.
    *   **Update Plan:** Once a task or sub-task is successfully completed **and verified to be error-free**, immediately update the `@/mediswitch_plan.md` file by changing the corresponding marker to `[x]`.
    *   **Iterate:** Proceed to the next logical task based on the plan.
4.  **Ask Before Deciding:** **Do not make assumptions or decisions.** If a task is ambiguous, requires choosing between options (like library choices, implementation details not specified in the plan), or if you are unsure about the next step, **you MUST ask for clarification** using the `ask_followup_question` tool before proceeding. Follow the user's direction.
5.  **Use Tools Correctly:** Execute file operations, commands, and other actions using the available tools one step at a time, waiting for confirmation after each tool use. Pay close attention to file paths and command syntax. Use `apply_diff` for targeted changes and `write_to_file` for new files or complete rewrites.
6.  **Refer to Core Documents:** Constantly refer back to `@/app_prompt.md` for feature requirements and `@/mediswitch_plan.md` for implementation details and status.
7.  **Maintain Structure & Organization:** **CRITICAL:** Adhere strictly to the established project structure (Clean Architecture) and coding conventions. Work in a methodical, organized manner, avoiding random changes.


**Your First Task (Reiteration):**

*   Perform the steps outlined in **Instruction #1 (Understand the Current State)** above.
*   Based on your analysis of the plan (`@/mediswitch_plan.md`) and the current codebase state, identify and propose the *single most logical next task* to implement according to the plan and the established methodology. Await user confirmation before proceeding with implementation.
