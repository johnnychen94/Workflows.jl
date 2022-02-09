import numpy as np
import json
from utils import belapsed

rst: dict = {}
for n in [64, 128, 256, 512, 1024, 2048]:
    rst[n] = {"time": belapsed(lambda: np.random.randn(n), number=100)}

print(json.dumps(rst))
