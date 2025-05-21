#!/bin/sh

############################ Inputs ############################
#$1 --> Input File
#$2 --> Number of lines to retrieve


get_seeded_random()
{
  seed="$1"
  openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt \
    </dev/zero 2>/dev/null
}

sort --random-source=<(get_seeded_random 42) -R "$1"| head -$2
