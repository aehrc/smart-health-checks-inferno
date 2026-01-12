-include .env

compose = docker compose
inferno = run inferno
rm_generated = rm -rf lib/smart_health_checks_test_kit/generated/v$(IG_VERSION_NUMBER)
ber_generate = bundle exec rake smart_health_checks:generate
lint_generated = rubocop -A lib/smart_health_checks_test_kit/generated/v$(IG_VERSION_NUMBER)

.PHONY: setup generate summary new_release tests run pull build up stop down rubocop migrate clean_generated ig_download uploadfig_generate_local

setup: pull build migrate

generate:
	$(rm_generated)
	$(compose) $(inferno) $(ber_generate)
	$(compose) $(inferno) $(lint_generated)

generate_local:
	$(rm_generated)
	$(ber_generate)
	$(lint_generated)

tests:
	$(compose) run -e APP_ENV=test inferno bundle exec rspec

run: build up

pull:
	$(compose) pull

build:
	$(compose) build

up:
	$(compose) up

stop:
	$(compose) stop

down:
	$(compose) down --remove-orphans

rubocop:
	$(compose) $(inferno) rubocop

rubocop-fix:
	$(compose) $(inferno) rubocop -A

migrate:
	$(compose) $(inferno) bundle exec rake db:migrate

clean_generated:
	sudo $(rm_generated)
	git checkout lib/smart_forms_test_kit/generated/

full_develop_restart: stop down generate setup run

prepare_new_config:
	@echo "IG_VERSION_NUMBER=$(IG_VERSION_NUMBER)"
	@echo "IG_VERSION_STRING=$(IG_VERSION_STRING)"
	python3 config.py
