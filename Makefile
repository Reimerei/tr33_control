export SERIAL_PORT = ttyUSB0

run:
	iex -S mix phx.server

deps-get:
	mix deps.get

deps-update:
	mix deps.update --all