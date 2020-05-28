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
