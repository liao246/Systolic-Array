import numpy as np

l = []
for x in range(100):
    a = np.random.uniform(-255, 255, 2).astype(np.float16)
    b = np.float16(np.random.uniform(-65504, 65504))
    c = np.float16(a[0] * a[1] + b)
    l.append(np.array((a[0], a[1], b, c), dtype=np.float16).view(np.uint16))

l = np.array(l, dtype=np.uint16)

l.tofile("float_test_fma.b")
for an, bn, a1n, cn in l:
    print(f"{an:#x} {bn:#x} {a1n:#x} {cn:#x}")