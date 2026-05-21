# Designer Instructions: UX Audit Workflow

Designers work in the **projects repo**. The skill repo is tooling that the LLM/operator installs and updates.

## 1. Install GitHub CLI if needed

Check whether `gh` is installed:

```sh
gh --version
```

If it is missing on macOS, install it with Homebrew:

```sh
brew install gh
```

Then sign in:

```sh
gh auth login
```

GitHub CLI docs:

https://cli.github.com/

## 2. Clone the projects repo first

This is the repo where designer audit work goes.

```sh
mkdir -p ~/ux-audits
cd ~/ux-audits
gh repo clone RoleModel/rolemodel-ux-audit-projects
```

Live projects repo URL:

https://github.com/RoleModel/rolemodel-ux-audit-projects

Fallback without `gh`:

```sh
git clone https://github.com/RoleModel/rolemodel-ux-audit-projects.git
```

## 3. Do not clone every demo by default

Do **not** use this unless you intentionally want every submodule:

```sh
git clone --recurse-submodules https://github.com/RoleModel/rolemodel-ux-audit-projects.git
```

Normal clone keeps the repo light. Demo apps live as submodules and are not hydrated unless requested.

If you need one demo, hydrate only that demo:

```sh
cd ~/ux-audits/rolemodel-ux-audit-projects
git submodule update --init rapidair/rapidair-redesign
```

## 4. Clone the skill repo for the LLM/operator

The LLM uses this repo to install `/ux-audit` and generate reports. Designers should not copy skill files by hand.

```sh
cd ~/ux-audits
gh repo clone RoleModel/rolemodel-design-audit
```

Live skill repo URL:

https://github.com/RoleModel/rolemodel-design-audit

Fallback without `gh`:

```sh
git clone https://github.com/RoleModel/rolemodel-design-audit.git
```

## 5. Ask the LLM to install or update the skill for the LLM tool being used

Tell the LLM:

```txt
Install or update the RoleModel UX audit skill by symlinking ~/ux-audits/rolemodel-design-audit/skills/ux-audit into the LLM tool I use. Do not copy the skill unless symlinks are impossible.
```

Use the command for the tool being used.

Claude Code:

```sh
mkdir -p ~/.claude/skills
ln -sfn ~/ux-audits/rolemodel-design-audit/skills/ux-audit ~/.claude/skills/ux-audit
```

Codex / skillshare:

```sh
mkdir -p ~/.config/skillshare/skills
ln -sfn ~/ux-audits/rolemodel-design-audit/skills/ux-audit ~/.config/skillshare/skills/ux-audit
```

opencode:

```sh
mkdir -p ~/.config/opencode/skills
ln -sfn ~/ux-audits/rolemodel-design-audit/skills/ux-audit ~/.config/opencode/skills/ux-audit
```

Cursor or other repo-local agents:

```sh
mkdir -p ./.cursor/skills
ln -sfn ~/ux-audits/rolemodel-design-audit/skills/ux-audit ./.cursor/skills/ux-audit
```

If the repo provides a setup script, the LLM/operator may use it, but the expected result is still a symlink from the active LLM tool to the source skill folder.

## 6. Create a project folder in the projects repo

All audit artifacts should go under `rolemodel-ux-audit-projects/<project-slug>/audit/`.

Example:

```sh
cd ~/ux-audits/rolemodel-ux-audit-projects
mkdir -p rapidair/audit
```

## 7. Open the app you want audited

Open the app locally, or tell the LLM which app/repo should be audited.

Example:

```txt
Audit ~/client-project. The app runs locally at http://localhost:3000. Put the audit artifacts in ~/ux-audits/rolemodel-ux-audit-projects/<project-slug>/audit/.
```

## 8. Ask the LLM to run the audit

Tell the LLM:

```txt
Run /ux-audit for this app and produce the internal HTML audit for designer review. Store the output in the projects repo under <project-slug>/audit/.
```

The first pickup artifact is the internal HTML audit.

## 9. Review the internal HTML audit

Open the HTML audit and review it as the working draft.

Look for:

1. findings that are correct
2. findings that need better wording
3. missing screenshots or evidence
4. recommendations that need design judgment
5. sections that should be removed before the client version

## 10. Refine the audit with the LLM

Tell the LLM what needs to change.

Example:

```txt
Tighten the executive summary, remove weak findings, and make the recommendations more client-ready.
```

## 11. Produce the reviewed PDF with paged-document

After the audit content is reviewed, ask the LLM:

```txt
Use the paged-document workflow to turn this reviewed audit into a polished PDF. Save the HTML and PDF outputs in the same <project-slug>/audit/ folder.
```

This PDF is the finalized reviewed document.

## 12. Move to Figma only if redesign work is needed

If the audit recommends redesign exploration, ask the LLM:

```txt
Pull the relevant app screens into Figma so I can explore the redesign direction.
```

Only do this when visual redesign work is actually needed.

## 13. Return to /ux-audit for client deliverables

After review, PDF finalization, and any Figma work, ask the LLM:

```txt
Create the client-facing deliverable from the finalized audit. Use the magazine HTML or Reveal presentation format as appropriate. Save it in the projects repo under <project-slug>/audit/.
```

Reveal slides are a final/client deliverable, not the first designer pickup artifact.

## 14. Publish the static report with GitHub Pages

Tell the LLM:

```txt
Publish the static audit report to GitHub Pages through the rolemodel-ux-audit-projects repo. Use the project slug <project-slug>.
```

One-command publish:

```sh
~/ux-audits/rolemodel-design-audit/skills/ux-audit/scripts/publish-report.sh <output-dir> \
  --provider github-pages \
  --name <project-slug> \
  --projects-repo ~/ux-audits/rolemodel-ux-audit-projects \
  --commit \
  --push
```

Published URL pattern:

```txt
https://rolemodel.github.io/rolemodel-ux-audit-projects/<project-slug>/audit
```

RapidAir example:

https://rolemodel.github.io/rolemodel-ux-audit-projects/rapidair/audit

## 15. Add an interactive demo link only when needed

Use GitHub Pages for the static audit report.

Use Vercel only when the recommendation needs an interactive prototype.

RapidAir demo example:

https://rapidair.vercel.app

## 16. Add a new interactive demo as a submodule

If a project needs a real demo app, create or use a separate GitHub repo for that demo. Then add it as a submodule from the projects repo:

```sh
cd ~/ux-audits/rolemodel-ux-audit-projects
git submodule add https://github.com/RoleModel/<demo-repo>.git <project-slug>/<demo-slug>
git commit -m "Add <project-slug> demo submodule"
git push
```

This keeps the projects repo light. Designers only hydrate the demo they need.

## One-command publish example

```sh
./skills/ux-audit/scripts/publish-report.sh dev-tools/ux-audit-output \
  --provider github-pages \
  --name rapidair \
  --projects-repo ~/ux-audits/rolemodel-ux-audit-projects \
  --commit \
  --push
```
