# GitHub Pages Publishing

GitHub Pages is the default publishing target for static UX audit reports.

This is publishing behavior, not a Google Docs template. The reusable logic belongs in this `/ux-audit` skill repo. The generated output belongs in the sibling `rolemodel-ux-audit-projects` catalog repo.

## Repo responsibilities

### `rolemodel-design-audit`

Owns reusable workflow code:

- `/ux-audit` skill instructions
- report templates
- publish scripts
- provider-specific publishing behavior

### `rolemodel-ux-audit-projects`

Owns generated artifacts:

- `<project-slug>/audit/`
- static report bundles
- playbooks and supporting artifacts
- `<project-slug>/<demo-slug>/` submodules for interactive prototypes

## URL pattern

```txt
https://rolemodel.github.io/rolemodel-ux-audit-projects/<project-slug>/audit
```

## Intended publish flow

1. Generate the static audit report bundle.
2. Run the publish script with `github-pages` as the provider.
3. Resolve the projects repo path.
4. Copy the report bundle into `<project-slug>/audit/`.
5. Ensure `.nojekyll` exists at the projects repo root.
6. Print the final GitHub Pages URL.
7. Commit and push when `--commit --push` are passed.

## Intended command

```sh
./publish-report.sh <output-dir> \
  --provider github-pages \
  --name <project-slug> \
  --projects-repo ~/rolemodel-ux-audit-projects \
  --commit \
  --push
```

## Vercel boundary

Use GitHub Pages for static audit reports.

Use Vercel for interactive demos, private previews, or prototypes with their own runtime.
