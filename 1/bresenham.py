# Bresenham's line implementation (for comparison)
# From: graphics.stanford.edu/courses/cs248-98-fall/line.ps
def bresenham_line(x0, y0, x1, y1):

    reflx = False
    refly = False
    reflxy = False

    def fragment(x, y):

        if reflxy: x, y = y, x
        if reflx: x = -x
        if refly: y = -y

        return x + x0, y + y0

    def line_impl(x, y, n, a, b, c):
        ap = 2 * a
        bp = 2 * b
        cp = 2 * c + b

        e = ap * x + bp * y + cp

        xs, ys = [], []

        while n >= 0:
            px, py = fragment(x, y)
            xs.append(px)
            ys.append(py)
            x += 1
            e += ap
            if e < 0:
                y += 1
                e += bp
            n -= 1

        return xs, ys

    dx = x1 - x0
    dy = y1 - y0

    if dx < 0:
        dx = -dx
        reflx = True

    if dy < 0:
        dy = -dy
        refly = True

    if dx < dy:
        dx ^= dy
        dy ^= dx
        dx ^= dy
        reflxy = True

    a = -dy
    b = dx
    c = 0
    n = dx

    return line_impl(0, 0, n, a, b, c)
