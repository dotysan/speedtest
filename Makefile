SHELL:= /usr/bin/env bash
PY:= python3.12

venv:= .venv
vb:= $(venv)/bin

PIP_CACHE_DIR:= $(CURDIR)/.pip
export PIP_CACHE_DIR

NPM_CONFIG_CACHE:= $(CURDIR)/.npm
export NPM_CONFIG_CACHE

define vrun
	source $(vb)/activate && $(1)
endef

node_modules: $(vb)/yarn
	$(call vrun,yarn install)

$(vb)/yarn: $(vb)/npm
	$(call vrun,npm install --global yarn)

$(vb)/npm: $(vb)/nodeenv
	$(call vrun,nodeenv --python-virtualenv --node=20.18.0 && \
		touch -r $(vb)/activate.csh $(vb)/activate && \
		npm install --global npm)
# Note that nodeenv --python-virtualenv above modifies activate,
# so we must reset the mtime to prevent successive runs of make
# from re-installing everything below

$(vb)/nodeenv: $(vb)/pip
	$(call vrun,pip install nodeenv)

$(vb)/pip: $(vb)/activate
	$(call vrun,pip list --format=freeze \
		|grep -oE '^[^=]+' \
		|xargs pip install --upgrade)

$(vb)/activate:
	$(PY) -m venv $(venv)

.PHONY: clean
clean:
	@if [[ -z "$(venv)" || ! -d "$(venv)" || $(venv) =~ / ]]; then \
		echo "ERROR: venv $(venv) is not a valid directory or contains slashes. Aborting."; \
		exit 1; \
	fi >&2
	rm --force --recursive $(venv)* .pip .npm node_modules
