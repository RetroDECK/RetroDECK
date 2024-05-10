#!/usr/bin/env python 
import os, sys
import zlib

def crc32(fileName):
    prev = 0
    for eachLine in open(fileName,"rb"):
        prev = zlib.crc32(eachLine, prev)
    return "%X"%(prev & 0xFFFFFFFF)

print(crc32(sys.argv[1]).lower())
