# Docker Compose Lab

This lab is intended to give you practical experience in the following things:

* Writing and updating your own Docker Compose file.
* Using Docker Compose to discover running ports.
* Utilizing networks to ensure application isolation (and simplify config).
* Debugging container failures.

## Introduction

This lab uses git tags, to "jump ahead" in time. Before you get started, make sure you checkout the tag for `1-in-memory-implementation`.

```
$ git checkout 1-in-memory-implementation
```

This lab also assumes you're using the docker-toolbox for MacOS (and are therefore using a Docker machine).


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

It turns out that the `0.0.0.0` in the Docker commands refers to the Docker machine, a VirtualBox VM that is running on your computer. You can get the IP address for that machine using the `docker-machine ip` command.

```
$ docker-machine ip
192.168.99.100
```

So, using the port and IP address together, I can talk to the service.


```
$ curl http://192.168.99.100:32768/value
{"value": "None"}
$ curl -X POST http://192.168.99.100:32768/value -H "Content-Type: application/json" -d '{"value": "potato"}'
$ curl http://192.168.99.100:32768/value
{"value": "potato"}
```

We've proven what we need to, so go ahead and tear down the Docker Compose environment. Hit `CTRL + C` to exit.

Alright! Let's complicate our lives a little bit! Move on to the next tag.

```
$ git checkout 2-adding-redis-container
```

## Part 2: Debugging Failed Containers

Let's relaunch the environment, using the detached mode (`-d` flag). We're using detatched mode to simulate the way a lot of automated systems will interact with Docker.

```
$ docker-compose build
$ docker-compose up -d
Creating network "dockercomposelab_default" with the default driver
Creating dockercomposelab_webservice_1 ...
Creating dockercomposelab_webservice_1 ... done
```

But there's an issue. Let's try and find the running containers.

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

Huh. It looks like our container already died. We can ask `docker ps` to show us stopped containers.

```
$ docker ps --filter status=exited
CONTAINER ID        IMAGE                         COMMAND             CREATED             STATUS                     PORTS               NAMES
5d85bafe5fde        dockercomposelab_webservice   "python app.py"     6 minutes ago       Exited (1) 6 minutes ago                       dockercomposelab_webservice_1
```

Now, we can fetch the logs for that container.

```
$ docker logs 5d85bafe5fde
Expected REDIS_URL to be set. Exiting.
```

Ah. So we need to set up a Redis server.


## Part 3: Adding a Redis Server

We're going to need to do the following:

* Add the Redis container to our Docker Compose
* Configure the application to connect to the Redis container.

### Adding the Redis Container

We're going to visit [Docker Hub](hub.docker.com) to look for a Redis container. Once we find it, we'll add the following to our Docker Compose file:

```
  redis:
    image: redis:3.2
    ports:
      - "0:6379"
```

This will let us launch a Redis server along with our environment.

### Adding Configuration Bits

Docker based applications try to pull as much configuration as possible from the environment.

```
        redis_url = os.environ["REDIS_URL"]
```

So, if we set the environment for the Docker container to point to the new redis container, all will be set.

```
  webservice:
    build: ./app
    ports:
      - "0:8080"
    environment:
      - "REDIS_URL=redis"
```

### Testing Your Changes

You may have noticed there's now a `scripts/` directory. In it are two scripts, `get_value.sh` and `set_value.sh`. Take a minute to look at them and convince yourself of what they do. Then, use the scripts to interact with the service.

```
$ scripts/get_value.sh
{"value": "None"}

$ scripts/set_value.sh turtle

$ scripts/get_value.sh
{"value": "turtle"}
```

Now that you've gotten this working, it's time to move to the next tag. Make sure to tear down the Docker Compose environment and discard your changes to your Docker Compose file first.

```
$ docker-compose down
$ git checkout -- .
$ git checkout 3-added-redis-container
```

## Part 4: Playing with Docker Networks

You'll notice that there's something strange about our configuration. 

```
    environment:
      - "REDIS_URL=redis"
```

We're basically setting the hostname to `redis`. How does this work? According to the [Docker documentation](https://docs.docker.com/compose/networking/), it has to do with Docker networks.

> By default Compose sets up a single network for your app. Each container for a service joins the default network and is both reachable by other containers on that network, and discoverable by them at a hostname identical to the container name.

We can test this by relaunching the Compose system, and then using `docker network ls` to find our networks.

```
$ docker-compose up -d
$ docker network ls
~/src/docker-compose-lab (master) $ docker network ls
NETWORK ID          NAME                       DRIVER              SCOPE
c263db97f633        dockercomposelab_default   bridge              local
```

Aha! We can also use `docker ps` to find the individual containers.

```
$ docker ps
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                     NAMES
3e7693ab5a51        dockercomposelab_webservice   "python app.py"          3 hours ago         Up 3 hours          0.0.0.0:32780->8080/tcp   dockercomposelab_webservice_1
0a6ab7ac9fe1        redis:3.2                     "docker-entrypoint..."   3 hours ago         Up 3 hours          0.0.0.0:32779->6379/tcp   dockercomposelab_redis_1
```

Once we find it, we can launch a bash shell inside our webservice container, then ping redis. 

```
$ docker exec -it dockercomposelab_webservice_1 bash
root@3e7693ab5a51:/usr/src/app# ping redis
64 bytes from 172.18.0.2: icmp_seq=0 ttl=64 time=0.074 ms
64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.111 ms
64 bytes from 172.18.0.2: icmp_seq=2 ttl=64 time=0.088 ms
64 bytes from 172.18.0.2: icmp_seq=3 ttl=64 time=0.088 ms
```

Cool. Docker networks make it really easy to connect across containers. 

As an exercise, add a second Redis container to your Docker Compose, with a different name. Bring the system down and back up, and prove that you're able to ping the newly created container.

When you're done, tear down the Docker Compose environment, reset your files, and move on to the next tag.

```
$ docker-compose down
$ git checkout -- .
$ git checkout 4-broken-port-config
```

## Part 5: Networks and Ports, Oh My!

That tag name can't bode well, can it? Ok, let's see what's broken!

```
$ docker-compose up -d
Recreating dockercomposelab_redis_1 ...
dockercomposelab_webservice_1 is up-to-date
Recreating dockercomposelab_redis_1
Creating dockercomposelab_otherredis_1 ...
Recreating dockercomposelab_redis_1 ... error

ERROR: for dockercomposelab_redis_1  Cannot start service redis: driver failed programming external connectivity on endpoint dockercomposelab_redis_1 (0a1cbd7d1b4572cc8e6685a6670cddc897be3464821374b8b544ff792767192c): Bind for 0.0.0.0:6379 failed: port is already allocated

ERROR: for redis  Cannot start service redis: driver failed programming external connectivity on endpoint dockercomposelab_redis_1 (0a1cbd7d1b4572cc8e6685a6670cddc897be3464821374b8b544ff792767192c): Bind for 0.0.0.0:6379 failed: port is already allocated
ERROR: Encountered errors while bringing up the project.
```

Yowch. It looks like we have some port conflict issues. Looking at our new Docker Compose file, we can see the issue pretty clearly.

```
version: '2.1'
services:
  webservice:
    build: ./app
    ports:
      - "0:8080"
    environment:
      - "REDIS_URL=redis"

  redis:
    image: redis:3.2
    ports:
      - "6379:6379"

  otherredis:
    image: redis:3.2
    ports:
      - "6379:6379"
```

For added context, we've got [this documentation](https://docs.docker.com/compose/compose-file/#ports) avaliable from docker. Essentially, the problem is that we're binding two containers to the same port on the host (6379). To fix this immediate issue, you can change at least one or the other to use a different port on the host. However, all is not quite well yet.

To demonstrate the issue, first tear down and start up the Docker Compose environment, then launch a _second_ Docker Compose instance using a different project name with the `-p` flag.

```
$ docker-compose up -d
$ docker-compose -p otherproj up -d
```

The second Compose will fail with an identical error, because ports it needs are already in use. This is an important lesson: when you bind to a fixed port in a Docker Compose file, any other Compose system that attempts to use the same port will fail. Whenever possible, use `0:` to get a randomly assigned port on the host system. As we've shown, it's easy enough to use `docker-compose port` to find the ports you need. 

## Conclusion

That's about it for this lab. Thanks for playing along!
