# Agent Deliverable Contract

contract_version: 1.0

Every sub-agent output must contain:
1. `summary`
2. `changed_files`
3. `status` (`pass` | `fail` | `blocked`)
4. `checks` (commands + results)
5. `next_action`

If `status != pass`, orchestrator must stop pipeline progression and decide remediation.
