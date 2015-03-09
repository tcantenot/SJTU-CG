import argparse
import matplotlib.pyplot as plt
import numpy as np

# For comparison only when a == 0 -> y = ax^2 + bx + c = bx + c => line
from bresenham import bresenham_line


# TODO: Handle a < 0
def incremental_poly(a, b, c, range_x):

    """
    Incremental evaluation of the polynomial ax^2 + bx + c using finite differences
    """

    # Discrete range of x values
    x0, xn = range_x[0], range_x[-1]

    # Initializations
    x = x0
    y = a * x**2 + b * x + c   # Polynomial equation
    e = 0                      # Error term: e(x, y) = F(x, y) = y - (ax^2 + bx + c)
    dedx = -2 * a * x - a - b  # dedx(x, y) = e(x+1, y) - e(x, y) = -2ax - a - b
    dedy = 1                   # dedy(x, y) = e(x, y+1) - e(x, y) = 1
    ddedx = -(a + a)           # ddedx(x, y) = dedx(x+1, y) - dedx(x, y) = -2a
    ddedy = 0                  # ddedy(x, y) = dedy(x, y+1) - dedy(x, y) = 0

    xs, ys = [], []

    while x <= xn:

        xs.append(x)
        ys.append(y)

        assert e == y - (a * x**2 + b * x + c)

        # Go up
        e += dedy
        dedy += ddedy
        y += 1

        # If we above the curve, go right
        if e > 0:
            e += dedx
            dedx += ddedx
            x += 1

    return np.array(xs), np.array(ys)


# Compute reference polynome
ref_poly = np.vectorize(lambda a, b, c, x: a * x**2 + b * x + c)


if __name__ == "__main__":

    # Available args
    parser = argparse.ArgumentParser(description=
        'Rasterize a second-degree polynomial (y = ax^2 + bx + c) incrementally'
    )

    parser.add_argument('-a', type=int, default=1, help='a coefficient')
    parser.add_argument('-b', type=int, default=1, help='b coefficient')
    parser.add_argument('-c', type=int, default=1, help='c coefficient')
    parser.add_argument('--xmin', type=int, default=1, help='Minimum x')
    parser.add_argument('--xmax', type=int, default=500, help='Maximum x')
    parser.add_argument('--err', action='store_true', help='Compute and display relative error on y')

    args = parser.parse_args()

    a = args.a
    b = args.b
    c = args.c
    x0 = args.xmin
    xn = args.xmax

    range_x = xrange(x0, xn+1)

    plt.figure(0)
    plt.title('Polynomial: y = {}x^2 + {}x + {}'.format(a, b, c));

    # Bresenham's line
    if a == 0:
        b_xs, b_ys = bresenham_line(x0, b * x0 + c, xn, b * xn + c)
        plt.plot(b_xs, b_ys, color='green', label="Bresenham")

    # Polynomial computed incrementally
    # Note: x values can have duplicates (for rasterization)
    xs, ys = incremental_poly(a, b, c, range_x)
    plt.plot(xs, ys, color='blue', label="Incremental")

    # Reference polynomial computed using the formula
    ref_ys = ref_poly(a, b, c, range_x)
    plt.plot(range_x, ref_ys, color='red', label="Reference")

    plt.legend(loc=2)
    plt.show(block=False)

    # Compute relative error
    if args.err:
        # Get y values for unique values of x
        new_ys = ys[np.sort(np.unique(xs, return_index=True)[1])]

        # Compute relative error on y
        relative_error_y = [abs(l - r) / r if r != 0 else 0 for (l, r) in zip(new_ys, ref_ys)]

        plt.figure(1)
        plt.title('Relative error on y')
        plt.plot(range_x, relative_error_y)

    plt.show()
