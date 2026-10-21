# QuestionnaireUsageTracing plugin

TODO: what this plugin generates and why.

## Enable it

Add the plugin to the generator config, keyed by its id:

```json
"plugins": {
  "questionnaire_usage_tracing": { "path": "plugins/questionnaire_usage_tracing", "options": {} }
}
```

## Layout

- `plugin.yml`: id, version, entrypoint and class
- `lib/questionnaire_usage_tracing.rb`: the entrypoint the host requires
- `lib/questionnaire_usage_tracing/plugin.rb`: `generate(context)`, called once the host has generated its built-in tests
- `lib/questionnaire_usage_tracing/extractor.rb`: this plugin's data for each group
- `templates/`: ERB templates for `InfernoSuiteGenerator::Plugins::TestGenerator` subclasses
- `runtime/`: files the generated tests need at Inferno run time, copied by `context.install_runtime`

## Output

Group data goes under `questionnaire_usage_tracing` in `<group dir>/plugins.yml`, and suite data under `questionnaire_usage_tracing` in `<suite dir>/plugins.yml`.