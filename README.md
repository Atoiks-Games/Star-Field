# Star Field

> Go around the stars
>
> Glide across the sky
>
> In the deep Star Field
>
> It's kill or be killed
>
> Ready to take charge?

## What is going on?

`client/` contains the client, written in Lua, uses love2d, navigate to its folder and run `./build.sh help` and see how to build

`server/` contains the server, written in Java 8, build with gradle wrapper

## How to play

1. Someone start the server
2. You (the players) launch the client
3. Click on the screen buttons to set the connection information
4. Hit the start button (also located on the screen)
5. Assuming the client reaches the server, right click to move, left click to select, and more buttons

## Server Configuration

A file called `server.properties` in the server directory can modify the server.

The following sample configuration file uses all the possible parameters:

```
port=5000 
limit=10
```

Note:

* if port is non-positive integer, it will use the default which is 5000
* if limit is negative, that means the server will accept all players. Default capacity is 8