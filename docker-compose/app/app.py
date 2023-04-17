from bottle import Bottle, request
import json
import redis
import os
import sys

cache = {}

app = Bottle()

global r


@app.get("/")
def say_hello():
    return json.dumps({"message": "oh hai dere"})


@app.get("/value")
def get_value():
    return json.dumps({"value": str(r.get('value'))})


@app.post("/value")
def set_value():
    r.set("value", str(request.json['value']))


if __name__ == '__main__':
    redis_url = None
    try:
        redis_url = os.environ["REDIS_URL"]
    except KeyError:
        print("Expected REDIS_URL to be set. Exiting.")
        sys.exit(1)

    r = redis.StrictRedis(host=redis_url, port=6379, db=0)
    app.run(host="0.0.0.0")
