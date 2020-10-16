export SERIAL_PORT = ttyUSB0
export CACHE_PERSIST_DIR = $(HOME)/.tr33_cache

console:
	iex -S mix phx.server

deps-get:
	mix deps.get

deps-update:
	mix deps.update --all

assets-update:
	npm update --save --force --prefix assets
	npm audit fix --force --prefix assets
	cd assets && npm install --force phoenix_live_view 

assets-build:
	npm --prefix assets run deploy && mix phx.digest
