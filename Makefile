export SERIAL_PORT = ttyUSB0
export CACHE_PERSIST_DIR = $(HOME)/.tr33_cache

console:
	iex -S mix phx.server

deps-get:
	mix deps.get

deps-update:
	mix deps.update --all

assets-build:
	npm --prefix assets run deploy && mix phx.digest

fprof:
	mix profile.fprof -e Tr33Control.Commands.Updater.do_update --sort own

cprof:
	mix profile.cprof -e Tr33Control.Commands.Updater.do_update

eprof:
	mix profile.eprof -e Tr33Control.Commands.Updater.do_update