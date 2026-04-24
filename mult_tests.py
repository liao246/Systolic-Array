import numpy as np

def is_subnormal(x):
    fmin_norm = np.finfo(type(x)).tiny
    return np.isfinite(x) & (x != 0) & (np.abs(x) < fmin_norm)

l = []
for x in range(100000):
    a = np.random.uniform(-255, 255, 2).astype(np.float16)
    c = np.float16(a[0] * a[1])
    l.append(np.array((a[0], a[1], c), dtype=np.float16).view(np.uint16))


for x in range(20000):
    a = np.random.uniform(-65504, 65504, 2).astype(np.float16)
    c = np.float16(a[0] * a[1])
    l.append(np.array((a[0], a[1], c), dtype=np.float16).view(np.uint16))


for x in range(20000):
    a = np.random.uniform(-2e-5, 2e-5, 2).astype(np.float16)
    c = np.float16(a[0] * a[1])
    if(is_subnormal(c)):
        c = np.float16(np.sign(a[0]) * np.sign(a[1]) * 0)
    l.append(np.array((a[0], a[1], c), dtype=np.float16).view(np.uint16))

for x in range(2000):
    a = np.float16(np.random.uniform(-65504, 65504))
    b = np.float16(0)
    c = np.float16(a * b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))

for x in range(2000):
    if(np.random.randint(0, 2) == 1):
        a = np.float16(np.random.uniform(-65504, 65504))
        b = np.float16(np.inf) if np.random.randint(0, 2) == 1 else np.float16(-np.inf)
    else:
        b = np.float16(np.random.uniform(-65504, 65504))
        a = np.float16(np.inf) if np.random.randint(0, 2) == 1 else np.float16(-np.inf)
    c = np.float16(a * b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))

for x in range(100):
    a = np.random.randint(0, 3)
    b = np.random.randint(0, 3)
    if(a == 0):
        a = np.float16(-np.inf)
    elif a == 1:
        a = np.float16(np.inf)
    else:
        a = np.float16(-0)
    
    if(b == 0):
        b = np.float16(-0)
    elif a == 1:
        b = np.float16(np.inf)
    else:
        b = np.float16(0)

    c = np.float16(a * b)
    l.append(np.array((a, b, c), dtype=np.float16).view(np.uint16))



l = np.array(l, dtype=np.uint16)

l.tofile("float_test_m.b")
for an, bn, cn in l:
    print(f"{an:#x} {bn:#x} {cn:#x}")