# [Phoenix Royale](http://phoenixroyale.com)

Hey! I'm Alex and this is my entry in [Phoenix Phrenzy](https://phoenixphrenzy.com), showing off what [Phoenix](https://phoenixframework.org/) and [LiveView](https://github.com/phoenixframework/phoenix_live_view) can do.

![PhoenixRoyale Preview](assets/static/images/preview.gif "PhoenixRoyale")

# Introduction

Phoenix Royale is a multiplayer, side-scrolling battle royale type game which aims to push Phoenix LiveView to it's limits (at least in terms on animation). Whilst a game such as this may not be the optimal use of LiveView, I've had a lot of fun trying to create a playable game which is rendered fully server-side. It also aims to demonstrate how easy it is to build a game which can handle many multiplayer games running simultaenously using Elixir/Erlang's GenServers, and how well this can be implemented on the frontend using Phoenix LiveView. 

## How to play

Visit [Phoenix Royale](http://phoenixroyale.com) to play with others, or run the project locally using the guide detailed below.

## About me

I currently work as an Elixir/Phoenix developer in Newcastle-upon-Tyne, in the North East on England. Elixir is the first language I have learnt in depth and one of the first tasks I had to do with the language was to create a GenServer game which could be played in the repl from two Node connected devices. It was a great introduction to Elixir and it left me wanting to work on something like this.

# The game

## Aim of the game

In order to win, you simply need to be the last alive. Avoid comets and other obstacles and collect Elixirs to increase your speed, whilst trying to fly away from the JavaStorm.

## Questions / Further comments

1. **How many people can play simultaneously in one game?** 

I'm not sure! I have set a maximum of 10 players in each game for now, I haven't been able to test this with more players.

2. **The hitboxes aren't perfect?** 

I know! I ran out of time developing the actual game itself, there was a lot more to be added and refining the hitboxes was something I would have liked to do with a bit more time. I think (*hope*) they are good enough to demonstrate the concept.

3. **Why is it the "JavaStorm"?** 

I wanted to make it so snippets of Java were chasing your Phoenix in a storm, but I did not have time to add this.

4. **It can lag quite a bit :(**

I'd love it if anyone would help out and make it smoother. I got it performing as well as I could. It is also hosted in the US, so please consider this! I am sure my HTML could also be cleaned up further to improve the framerate.

## How it works

When the application is started, a GameCoordinator GenServer starts up, this handles finding both single player and multiplayer games. When a player tries to start a game and there currently are no servers running, a GameServer GenServer is started up. For each player in the game there is an additional GameInstance GenServer. This is what each LiveView session talks to. This was the only way I could make it playable with a number of players! 

In addition, each player's GameInstance keeps the others updated, using a function I called `waterfall`, I am not really sure where I came to this name from as it doesn't really describe what it is doing.

The best way to look at what is going on is to dive in to the code itself! (If you're interested)

## The code

The code in this project is by no means fully finished. There is absolutely no documentation and not one test. There have been a number of iterations on how the live_view module connects to the GenServers actually running the game, in order to try and make it as playable as possible.

I have had many ideas for this game which I have had to omit due to being unable to dedicate enough time to working on this project. I have a big list of tasks which need doing with the game in it's current state, and also a list of further features which I had in mind. There is a lot of potential for refactoring the code, in particular the templates themselves need some tidying up. 

Hopefully the important parts of the code are reasonably succint and easy to read (The game server and instances, along with the corresponding royale_live module), whilst other areas could definitely be improved significantly (such as the map generation and game logic).

# Deployment

Phoenix Royale is deployed online [here!](http://phoenixroyale.com). It is currently deployed on Gigalixir using their free service which allows one the deployment on one application. The cluster is in the US so please bear in mind that performance may be affected when playing in the EU or elsewhere. Gigalixir was super easy to use and I would 100% recommend looking in to if you haven't used it already.

- [Gigalixir](https://gigalixir.com/)

## Running Phoenix Royale Locally

To start your own PhoenixRoyale server:

  * Install dependencies with `mix deps.get` or `make setup`
  * Create and migrate your database with `mix ecto.setup` or `make setup_db`
  * Install Node.js dependencies with `cd assets && npm install` or `make setup_static`
  * Start Phoenix endpoint with `mix phx.server` or simply `make`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser and get started. If you want to play multiplayer locally, check out a guide on how to connect multiple nodes [here](http://elixir-recipes.github.io/concurrency/connecting-nodes-different-machines/)

# Credits / Thanks

The vast majority of the credit for this application belongs with the creator's of Elixir, Phoenix and Phoenix LiveView as I simply did not need to worry about so many things to get this working!

There are a number of images and resources that have been used to create this application, these are listed here:

  * Materialize CSS - https://materializecss.com
  * CSS Waves - https://csspoints.com/css-wave-effect-responsive-design/
  * Lightouse png - http://www.freepngclipart.com/free-png/87867-lighthouse-free-download-png-hq
  * Boat png - https://pngtree.com/so/red_vessel
  * Comet png - https://pngtree.com/freepng/fireball-planet-planet-comet-halleys-comet_3929072.html

# Learn more

  * Official website: http://www.phoenixframework.org/
  * Elixir language official website: https://elixir-lang.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
