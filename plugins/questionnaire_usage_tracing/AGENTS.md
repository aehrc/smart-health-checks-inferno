# questionnaire_usage_tracing plugin: notes for agents

This folder is an inferno_suite_generator plugin. Keep every change inside it.

## Contract

- `plugin.yml` is the source of truth for the id, version, entrypoint and class. Bump `version` when the generated output changes.
- The class in `plugin.yml` takes no constructor arguments and defines `generate(context)`. `context` is an `InfernoSuiteGenerator::Plugins::Context`.
- Write plugin data only through `context.metadata` (`group`, `groups`, `suite`). It ends up under this plugin's id in `plugins.yml`.
- Never edit the host's `metadata.yml` or `demodata.yml`. Read them through `context.ig_metadata` and `context.ig_demodata`.
- Add text to a group's description only through `context.descriptions` (`group`, `groups`), with plain Markdown. Don't override or patch `GroupGenerator`.

## Where things go

- Data extraction: subclasses of `InfernoSuiteGenerator::Plugins::Extractor` in `lib/questionnaire_usage_tracing/`
- Test files: ERB templates in `templates/`, rendered by subclasses of `InfernoSuiteGenerator::Plugins::TestGenerator`
- Code the generated tests run in Inferno: `runtime/`, installed with `context.install_runtime`

## Check your work

Run RuboCop before finishing:

```bash
bundle exec rubocop plugins/questionnaire_usage_tracing
```
