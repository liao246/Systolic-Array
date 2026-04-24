import numpy as np
from ml_dtypes import float8_e4m3fn

def printHex(a, dtype):
    a = np.vectorize(hex)(a.view(dtype))
    print(a)
    print()

def mult(weights, inputs):
    result = np.zeros((8, 8), dtype=np.float16)
    for i in range(weights.shape[0]):
        for k in range(inputs.shape[1]):
            acc = np.float16(0)
            for j in range(weights.shape[1]):
                acc = np.float16(acc + np.float16(weights[i, j].astype(np.float16) * inputs[j, k].astype(np.float16)))
            result[i, k] = acc
    return result



weights = np.random.uniform(-4, 4, (8, 8)).astype(float8_e4m3fn)


inputs = (np.random.uniform(2e-2, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3fn)
result = mult(weights.astype(np.float16), inputs.astype(np.float16))

with open("mat.b", "wb") as fp:
    fp.write(weights.flatten(order="c").view(np.uint8).tobytes())
    for i in range(1):
        inputs = (np.random.uniform(2e-2, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3fn)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16))
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())



# printHex(weights.astype(np.float16), np.uint16)

# printHex(inputs, np.uint8)


# printHex(result, np.uint16)


# result1 = np.ndarray((8, 8), dtype=np.float16)
# result2 = np.ndarray((8, 8), dtype=np.float16)

# input1 = inputs[:,0].astype(np.float16)
# input2 = inputs[:,1].astype(np.float16)
# printHex(input1, np.uint16)
# printHex(input2, np.uint16)
# for x in range(0, 8):
#     result1[x] = input1.astype(np.float16) * weights[x].astype(np.float16)
#     result2[x] = input2.astype(np.float16) * weights[x].astype(np.float16)



# printHex(result1, np.uint16)

# printHex(result2, np.uint16)





# print("done")
