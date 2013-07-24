#!/usr/bin/env python
import string
import sys
import argparse

class Stat:
    def __init__(self, label, parent=None):
        self.count = 0
        self.size = 0
        self.label = 0
        self.parent = parent
    def update(self, size):
        self.count += 1
        self.size += size
        if self.parent:
            self.parent.update(size)

everything = Stat('total')
months = {}

parser = argparse.ArgumentParser(description='Summarize ingest counts from gf dump file. Output written to stdout.')
parser.add_argument('infile',
        type=argparse.FileType('r'),
        nargs='?',
        default=sys.stdin,
        help='The input dump file. defaults to stdin.')
args = parser.parse_args()


with args.infile as f:
    for line in f.readlines():
        items = line.split(',')
        if len(items) < 6:
            continue
        noid,cd,md,mime,size,user,label = items[:7]
        if user in ['dbrower@nd.edu','banurekha.l@nd.edu','lawrence.selvy.1@nd.edu']:
            continue
        try:
            size = int(size)
        except ValueError:
            continue
        month = cd[:7]
        try:
            months[month].update(size)
        except:
            months[month] = Stat(month,everything)
            months[month].update(size)
m = months.keys()
m.sort()
print "month,ingest_count,ingest_bytes"
for mm in m:
    print "%s,%d,%d" % (mm,months[mm].count,months[mm].size)

