![Overview](./images/compose.jpeg) 

# Docker Compose Lab

This lab is intended to give you practical experience in the following things:

* Writing and updating your own Docker Compose file.
* Using Docker Compose to discover running ports.
* Utilizing networks to ensure application isolation (and simplify config).
* Debugging container failures.

## Prequisite
Docker Compose Installation Guide: https://docs.docker.com/compose/install/standalone/
```
# Change to root privelege
sudo su -
# Download docker-compose binary
curl -SL https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
# Add execute permission
chmod +x /usr/local/bin/docker-compose
```

## Part 1: Introducing the Value Microservice.

The [app](app/) directory of this repo contains a tiny Dockerized Python microservice that we'll call the "value" service for now. It has a single endpoint, `/value`, with the following API.
* `GET /value` returns a JSON object with the key `value` set to the current value (a string).
* `POST /value` will set the current `value`.

It's a dumb microservice, and it's really only here to serve our Docker Compose system.  

To run the service, do the following.

```
$ docker-compose build
$ docker-compose up
```

You'll see the following messages once the microservice is online:

```
Recreating dockercomposelab_webservice_1 ...
Recreating dockercomposelab_webservice_1 ... done
Attaching to dockercomposelab_webservice_1
webservice_1  | Bottle v0.12.13 server starting up (using WSGIRefServer())...
webservice_1  | Listening on http://0.0.0.0:8080/
webservice_1  | Hit Ctrl-C to quit.
```

Sweet! However, the message is a little misleading. 

```
$ curl http://0.0.0.0:8080/
curl: (7) Failed to connect to 0.0.0.0 port 8080: Connection refused
```

What a tease. It turns out that the `0.0.0.0` refers to the container's network interface, not our computer's network interface.

We can see this pretty clearly if we use the `docker ps` command, and look at the `PORTS` column.


```
$ docker ps
CONTAINER ID        IMAGE                         COMMAND             CREATED             STATUS              PORTS                     NAMES
d32d5f6c0640        dockercomposelab_webservice   "python app.py"     27 minutes ago      Up 27 minutes       0.0.0.0:32768->8080/tcp   dockercomposelab_webservice_1
```

We can get just the mapping with the `docker-compose port` command. The following lets us find out which port has bound to port 8080 on the `webservice` service. 

```
$ docker-compose port webservice 8080
0.0.0.0:32768
```

Aha! So it must be on `0.0.0.0:32768`. Not so fast.

```
$ curl http://0.0.0.0:32768/
curl: (7) Failed to connect to 0.0.0.0 port 32768: Connection refused 
```

It turns out that the `0.0.0.0` in the Docker commands refers to the Docker Host IP. You can get the IP address for that machine using the `ifconfig` or `ip r` command. For simple just using `ip 127.0.0.1`

```
$ curl http://127.0.0.1:32768/value
{"value": "None"}
$ curl -X POST http://127.0.0.1:32768/value -H "Content-Type: application/json" -d '{"value": "potato"}'
$ curl http://127.0.0.1:32768/value
{"value": "potato"}
```

## Conclusion

That's about it for this lab. Thanks for playing along!
