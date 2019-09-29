run:
	iex --name alex@192.168.1.138 --cookie lobo -S mix phx.server

setup:
	mix deps.get

setup_db:
	mix ecto.create
	mix ecto.migrate

setup_static:
	cd assets && npm install
