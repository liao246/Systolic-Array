import numpy as np
from ml_dtypes import float8_e4m3fn


weights = np.random.uniform(-4, 4, (8, 8)).astype(float8_e4m3fn)
inputs = np.random.uniform(-4, 4, 8).astype(float8_e4m3fn)






inputs = inputs.reshape(-1, 1)

hexarr = np.vectorize(hex)(weights.view(np.uint8))
print(hexarr)
print()

hexarr = np.vectorize(hex)(inputs.view(np.uint8))
print(hexarr)
print()


result = np.zeros((8, 1), dtype=np.float16)
for i in range(weights.shape[0]):
    acc = np.float16(0)
    for j in range(weights.shape[1]):
        acc = np.float16(acc + np.float16(weights[i, j].astype(np.float16) * inputs[j, 0].astype(np.float16)))
    result[i, 0] = acc


with open("mat.b", "wb") as fp:
    fp.write(weights.flatten(order="c").view(np.uint8).tobytes())
    fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
    fp.write(result.flatten(order="f").view(np.uint16).tobytes())


inputs = inputs.reshape(1, -1).astype(np.float16)
weights = weights.astype(np.float16)

resulta = np.ndarray((8, 8), dtype=np.float16)

for x in range(0, 8):
    resulta[x] = weights[x].astype(np.float16) * inputs.astype(np.float16)


inputs = inputs.reshape(-1, 1)

hexarr = np.vectorize(hex)(weights.view(np.uint16))
print(hexarr)
print()

hexarr = np.vectorize(hex)(inputs.view(np.uint16))
print(hexarr)
print()

hexarr = np.vectorize(hex)(resulta.view(np.uint16))
print(hexarr)
print()
# hexarr = np.vectorize(hex)(result.view(np.uint16))
# print(hexarr)
# print()


print("done")
