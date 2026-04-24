import numpy as np
from ml_dtypes import float8_e4m3

def to_e4m3_preserve_inf(x: np.ndarray):
    x = x.astype(np.float16)

    is_pos_inf = np.isposinf(x)
    is_neg_inf = np.isneginf(x)
    is_nan     = np.isnan(x)

    y = x.astype(float8_e4m3)

    y = y.view(np.uint8)

    y[is_pos_inf] = 0x78  
    y[is_neg_inf] = 0xF8  

    y[is_nan] = 0x7F

    return y

def printHex(a, dtype):
    a = np.vectorize(hex)(a.view(dtype))
    print(a)
    print()

def printHex1(a, dtype):
    # Reinterpret raw bytes safely
    raw = np.frombuffer(a.tobytes(), dtype=dtype)
    raw = raw.reshape(a.shape)
    print(np.vectorize(hex)(raw))
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



weights = np.random.uniform(-4, 4, (8, 8)).astype(float8_e4m3)


inputs = (np.random.uniform(2e-2, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
result = mult(weights.astype(np.float16), inputs.astype(np.float16))



with open("mat.b", "wb") as fp:
    fp.write(weights.flatten(order="c").view(np.uint8).tobytes())
    for i in range(5):
        inputs = (np.random.uniform(2e-1, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = result.astype(float8_e4m3)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())
    for i in range(5):
        inputs = (np.random.uniform(2e-1, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = (result.astype(float8_e4m3) > 0).astype(float8_e4m3)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())
    weights = np.random.uniform(-4, 4, (8, 8)).astype(float8_e4m3)
    fp.write(weights.flatten(order="c").view(np.uint8).tobytes())
    printHex(weights, np.uint8)
    for i in range(5):
        inputs = (np.random.uniform(2e-1, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = np.maximum(result.astype(float8_e4m3), 0).astype(float8_e4m3)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())
    for i in range(5):
        inputs = (np.random.uniform(2e-1, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = np.where(result.astype(float8_e4m3) > 0, result.astype(float8_e4m3), result.astype(float8_e4m3) / 4).astype(float8_e4m3)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())
    for i in range(5):
        inputs = (np.random.uniform(2e-2, 450, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = to_e4m3_preserve_inf(result)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())
    for i in range(5):
        inputs = (np.random.choice((-np.nan, np.nan), (8, 8))).astype(float8_e4m3)

        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = to_e4m3_preserve_inf(result)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())
    for i in range(2):
        inputs = (np.random.uniform(2e-1, 4, (8, 8)) * np.random.choice((-1, 1), (8, 8))).astype(float8_e4m3)
        bias = (np.random.uniform(2e-1, 4, (8, 1)) * np.random.choice((-1, 1), (8, 1))).astype(float8_e4m3)
        result = mult(weights.astype(np.float16), inputs.astype(np.float16)) + bias.astype(np.float16)
        result1 = result.astype(float8_e4m3)
        fp.write(inputs.flatten(order="f").view(np.uint8).tobytes())
        fp.write(bias.view(np.uint8).tobytes())
        fp.write(result.flatten(order="f").view(np.uint16).tobytes())
        fp.write(result1.flatten(order="f").view(np.uint8).tobytes())

# printHex(inputs, np.uint8)
# #printHex(bias, np.uint8)
# printHex(result1, np.uint8)
# print(result1.dtype)




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
