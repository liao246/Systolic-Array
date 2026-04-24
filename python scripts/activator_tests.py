import numpy as np
from ml_dtypes import float8_e4m3



inputs = (np.random.uniform(2e-2, 65504, 30) * np.random.choice([-1, 1], 30)).astype(np.float16)
inputs = np.concatenate((inputs, (np.random.uniform(2e-2, 500, 10000) * np.random.choice([-1, 1], 10000)).astype(np.float16), np.array([np.inf, -np.inf, np.nan, 0, -0], dtype=np.float16)))

relu = np.maximum(inputs, 0).astype(float8_e4m3)
binary = (inputs > 0).astype(float8_e4m3)
identity = inputs.astype(float8_e4m3)
leaky = np.where(inputs > 0, inputs, inputs / 4).astype(float8_e4m3)

print(np.vectorize(hex)(inputs.view(np.uint16)))
print(np.vectorize(hex)(relu.view(np.uint8)))
print(np.vectorize(hex)(binary.view(np.uint8)))
print(np.vectorize(hex)(identity.view(np.uint8)))
print(np.vectorize(hex)(leaky.view(np.uint8)))

with open("activations.b", "wb") as fp:
    fp.write(inputs.view(np.uint16).tobytes())
    fp.write(relu.view(np.uint8).tobytes())
    fp.write(binary.view(np.uint8).tobytes())
    fp.write(identity.view(np.uint8).tobytes())
    fp.write(leaky.view(np.uint8).tobytes())