# FRC 2713 Skills

Shared Claude Code and Codex skills for the Red Hawk Robotics software team.

## Install

In Claude Code:

```
/plugin marketplace add frc2713/skills
/plugin install frc2713-skills@frc2713
```

That's it — the skills are now available. To pick up new skills or updates later:

```
/plugin marketplace update frc2713
```

In Codex:

```
codex plugin marketplace add frc2713/skills --ref main
codex plugin add frc2713-skills@frc2713
```

Start a new conversation after installing or updating so the new skills are loaded.

Invoke skills with `/skill-name` in Claude Code or `$skill-name` in Codex.

## Skills

| Skill | What it does |
| --- | --- |
| `/teach-me <topic>` | An adaptive tutor. Calibrates what you already know, then guides you through the topic one step at a time, checking understanding as it goes. Curriculum-aware — it uses the `software_training` lessons as its syllabus. |
| `/review-my-code` | An interactive, teaching code review for your FRC / WPILib Java. Walks your code with you, surfaces issues worst-first, and guides you to fix them yourself instead of rewriting it. Not the automated branch review (that's `/code-review`). |
| `create-hawk-app` | Guides a non-programmer through checking their computer, creating a safe copy of the Hawk app template, describing their app, verifying it, and opening it locally. |

## Repository layout

This repo is a Claude Code and Codex **plugin marketplace**:

```
.claude-plugin/
  marketplace.json          # lists the plugins in this marketplace
.agents/plugins/
  marketplace.json          # Codex marketplace catalog
plugins/
  frc2713-skills/           # one plugin bundling all the team's skills
    .claude-plugin/
      plugin.json
    .codex-plugin/
      plugin.json
    skills/
      teach-me/
        SKILL.md            # one folder per skill
```

## Adding a skill

1. Create `plugins/frc2713-skills/skills/<skill-name>/SKILL.md`.
2. Give it YAML frontmatter with `name` and a `description` that clearly says
   *when* the skill should trigger (this is what Claude matches on).
3. Bump the version in both plugin manifests and the Claude marketplace entries.
4. Add a row to the Skills table above.
5. Open a PR. Once merged, teammates get it with `/plugin marketplace update frc2713`.

Use the `skill-creator` skill when adding or substantially changing a skill.
