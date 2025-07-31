compose = docker compose
inferno = run inferno

.PHONY: setup generate summary new_release tests run pull build up stop down rubocop migrate clean_generated ig_download uploadfig_generate_local

setup: pull build migrate

generate: uploadfig_download_ig_deps
	rm -rf lib/smart_health_checks_test_kit/generated/
	$(compose) $(inferno) bundle exec rake smart_health_checks:generate
	$(compose) $(inferno) rubocop -A lib/smart_health_checks_test_kit/

generate_local:
	rm -rf lib/smart_health_checks_test_kit/generated/
	bundle exec rake smart_health_checks:generate
	rubocop -A lib/smart_health_checks_test_kit/

summary: build
	$(compose) $(inferno) ruby lib/smart_health_checks_test_kit/generator/summary_generator.rb

new_release: build ig_download generate summary

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
	$(compose) down

rubocop:
	$(compose) $(inferno) rubocop

rubocop-fix:
	$(compose) $(inferno) rubocop -A

migrate:
	$(compose) $(inferno) bundle exec rake db:migrate

clean_generated:
	sudo rm -rf lib/smart_forms_test_kit/generated/
	git checkout lib/smart_forms_test_kit/generated/

full_develop_restart: stop down generate setup run

