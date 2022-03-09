import numpy as np
import json
from utils import belapsed
import sys

n = int(sys.argv[1])
x = np.random.rand(n)
rst = {
    "time": belapsed(lambda: x.sum(), number=100),
    "name": "sum",
    "size": n,
    "framework": "numpy",
}

print(json.dumps(rst))
