#!/usr/bin/env python
import json, yaml, sys
sys.stdout.write(yaml.dump(json.load(sys.stdin)))
