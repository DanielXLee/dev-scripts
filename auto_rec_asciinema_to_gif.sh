#!/bin/bash

rec_date_time=$(date +%F_%H-%M-%S)
asciinema rec ${rec_date_time}.cast
# the next line only needed when you install asciicast2gif by docker
docker run --rm -v $PWD:/data asciinema/asciicast2gif -S 1 ${rec_date_time}.cast ${rec_date_time}.gif
