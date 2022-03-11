import numpy as np
import json
from utils import belapsed
import sys

n = int(sys.argv[1])
rst = {
    "time": belapsed(lambda: np.random.rand(n), number=100),
    "name": "randn",
    "size": n,
    "framework": "numpy",
}

print(json.dumps(rst))
