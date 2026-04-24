import numpy as np

l = []
for x in range(100000):
    a = np.random.uniform(-65504, 65504, 2).astype(np.float16)
    c = np.float16(a[0] + a[1])
    l.append(np.array((a[0], a[1], c), dtype=np.float16).view(np.uint16))

for x in range(10000):
    if np.random.randint(0, 2) == 1:
        a = np.float16(np.random.uniform(-65504, -35000))
        b = np.float16(np.random.uniform(-65504, -35000))
    else:
        a = np.float16(np.random.uniform(35000, 65504))
        b = np.float16(np.random.uniform(35000, 65504))
    c = np.float16(a + b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))

for x in range(10000):
    a = np.float16(np.random.uniform(-65504, 65504))
    b = -a + np.float16(np.random.uniform(-2e-25, 2e-25))
    c = np.float16(a + b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))

for x in range(1000):
    a = np.random.randint(0, 3)
    b = np.random.randint(0, 3)
    a = np.float16(np.inf) if(a == 1) else (np.float16(-np.inf) if(a == 2) else np.float16(np.random.uniform(-65504, 65504)))
    b = np.float16(np.inf) if(b == 1) else (np.float16(-np.inf) if(b == 2) else np.float16(np.random.uniform(-65504, 65504)))
    c = np.float16(a + b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))

for x in range(1000):
    a = np.random.randint(0, 3)
    b = np.random.randint(0, 3)
    a = np.float16(np.nan) if(a == 1) else (np.float16(-np.nan) if(a == 2) else np.float16(np.random.uniform(-65504, 65504)))
    b = np.float16(np.nan) if(b == 1) else (np.float16(-np.nan) if(b == 2) else np.float16(np.random.uniform(-65504, 65504)))
    c = np.float16(a + b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))

l = np.array(l, dtype=np.uint16)

l.tofile("float_test.b")
for an, bn, cn in l:
    print(f"{an:#x} {bn:#x} {cn:#x}")