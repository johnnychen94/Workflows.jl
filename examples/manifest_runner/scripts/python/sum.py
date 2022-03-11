import random
import json
from utils import belapsed
import sys

n = int(sys.argv[1])
x = [random.random() for _ in range(n)]


def sum(x):
    rst = 0
    for x in x:
        rst += x
    return rst


rst = {
    "time": belapsed(lambda: sum(x), number=100),
    "name": "sum",
    "size": n,
    "framework": "python",
}

print(json.dumps(rst))
