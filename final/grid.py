import random


def random_grid(w, h):
    indices = [k for k in xrange(w * h)]
    random.shuffle(indices)
    return indices

def grid1(w, h):
    even = [k for k in xrange(0, w * h, 2)]
    odd  = [k for k in xrange(1, w * h, 2)]
    indices = even + odd
    indices = indices[:len(indices)][::-1] + indices[len(indices):][::-1]
    return indices

def grid2(w, h):

    even = []
    for y in xrange(w):
        i = y % 2
        for x in xrange(h):
            if (x+i) % 2:
                even.append(y * w + x)

    odd = []
    for y in xrange(w):
        i = (y+1) % 2
        for x in xrange(h):
            if (x+i) % 2:
                odd.append(y * w + x)

    odd = odd[::-1]
    even = even[:len(even)] + odd[len(odd):]
    odd  = even[len(even):] + odd[:len(odd)]

    indices = even + odd
    indices = indices[:len(indices)][::-1] + indices[len(indices):][::-1]

    return indices
