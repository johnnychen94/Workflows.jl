import timeit
import json

# setup and test
from skimage.data import shepp_logan_phantom
from skimage.morphology import dilation, square

img = shepp_logan_phantom() # (400, 400)
dilation(img, square(3))

# benchmark
count, time = timeit.Timer('dilation(img, square(3))', globals=globals()).autorange()

# export
print(json.dumps({"time": 1e3*time/count})) # ms
