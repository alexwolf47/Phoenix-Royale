run:
	iex --name alex@192.168.1.186 --cookie MONSTER -S mix phx.server

setup_static:
	cd assets && npm install