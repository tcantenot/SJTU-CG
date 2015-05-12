import numpy as np
import matplotlib.pyplot as plt


def B(i, j, ts):

    def _B1(t):
        return 1 if ts[i] <= t <= ts[i+1] else 0

    def _Bj(t):
        lhs = (t - ts[i]) / (ts[i+j-1] - ts[i]) * B(i, j-1, ts)(t);
        rhs = (ts[i+j] - t) / (ts[i+j] - ts[i+1]) * B(i+1, j-1, ts)(t);
        return lhs + rhs

    return _B1 if j == 1 else _Bj


if __name__ == "__main__":

    ts = [0, 1, 3, 4, 5]

    B04 = np.vectorize(B(0, 4, ts))
    B03 = np.vectorize(B(0, 3, ts))
    B02 = np.vectorize(B(0, 2, ts))
    B01 = np.vectorize(B(0, 1, ts))

    t = np.linspace(-3, 8, 1000)

    plt.plot(t, B01(t), label="B01(t)")
    plt.plot(t, B02(t), label="B02(t)")
    plt.plot(t, B03(t), label="B03(t)")
    plt.plot(t, B04(t), label="B04(t)")
    plt.legend(loc=2)
    plt.show()
