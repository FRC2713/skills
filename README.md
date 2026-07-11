# FRC 2713 Skills

Shared [Claude Code](https://claude.com/claude-code) skills for the Red Hawk
Robotics software team. Add the marketplace once and everyone gets the same set
of skills, updated with a `git pull`.

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

## Skills

| Skill | What it does |
| --- | --- |
| `/teach-me <topic>` | An adaptive tutor. Calibrates what you already know, then guides you through the topic one step at a time, checking understanding as it goes. Curriculum-aware — it uses the `software_training` lessons as its syllabus. |
| `/review-my-code` | An interactive, teaching code review for your FRC / WPILib Java. Walks your code with you, surfaces issues worst-first, and guides you to fix them yourself instead of rewriting it. Not the automated branch review (that's `/code-review`). |

## Repository layout

This repo is a Claude Code **plugin marketplace**:

```
.claude-plugin/
  marketplace.json          # lists the plugins in this marketplace
plugins/
  frc2713-skills/           # one plugin bundling all the team's skills
    .claude-plugin/
      plugin.json
    skills/
      teach-me/
        SKILL.md            # one folder per skill
```

## Adding a skill

1. Create `plugins/frc2713-skills/skills/<skill-name>/SKILL.md`.
2. Give it YAML frontmatter with `name` and a `description` that clearly says
   *when* the skill should trigger (this is what Claude matches on).
3. Bump the `version` in `plugin.json` and `marketplace.json`.
4. Add a row to the Skills table above.
5. Open a PR. Once merged, teammates get it with `/plugin marketplace update frc2713`.

See Anthropic's [skill authoring docs](https://docs.claude.com/en/docs/claude-code/skills)
for the full SKILL.md format, and the `skill-creator` skill if you want help
scaffolding one.
