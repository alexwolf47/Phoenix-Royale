run:
	iex --name alex@192.168.1.185 --cookie MONSTER -S mix phx.server

setup_static:
	cd assets && npm install