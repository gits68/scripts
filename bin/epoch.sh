#!/bin/sh
(( ! $# )) && exec date +%s
exec date -d @"$@"
