import matplotlib.pyplot as plt
import numpy as np


if __name__ == "__main__":

    t = np.linspace(0, 1, 100);

    # y
    x = t**2 - 2*t + 1
    y = t**3 - 2*t**2 + t
    plt.plot(x, y, label='Gamma')


    # n
    x = t**2 + 1
    y = t**3
    plt.plot(x, y, label='Eta')

    plt.legend(loc=2)
    plt.show()

    # y'
    x = 2*t - 2
    y = 3*t**2 - 4*t + 1
    plt.plot(x, y, label='Gamma\'')

    # n'
    x = 2*t
    y = 3*t**2
    plt.plot(x, y, label='Eta\'')

    plt.legend(loc=2)
    plt.show()
