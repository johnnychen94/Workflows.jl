import numpy as np
import json
from utils import belapsed

rst: dict = {}
for n in [64, 128, 256, 512, 1024, 2048]:
    x = np.random.rand(n)
    rst[n] = {"time": belapsed(lambda: x.sum(), number=100)}

print(json.dumps(rst))
