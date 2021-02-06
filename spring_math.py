import numpy as np

def spring(t, start_time, omega, damping_ratio, v0):
    zeta = damping_ratio
    t = t - start_time
    
    if zeta == 1.0:
        c1 = -1
        c2 = v0 - omega
        y = (c1 + c2 * t) * np.exp(-omega * t)
    elif zeta > 1:
        s1 = omega * (-zeta + np.sqrt(zeta ** 2 - 1))
        s2 = omega * (-zeta - np.sqrt(zeta ** 2 - 1))
        c1 = (-s2 - v0) / (s2 - s1)
        c2 = (s1 + v0) / (s2 - s1)
        y = c1 * np.exp(s1 * t) + c2 * np.exp(s2 * t)
    else:
        a = -omega * zeta
        b = omega * np.sqrt(1 - zeta ** 2)
        c1 = -1
        c2 = (v0 + a) / b
        y = c1 * np.exp(a * t) * np.cos(b * t) + c2 * np.exp(a * t) * np.sin(b * t)

    return np.where(t < 0, np.zeros_like(t), y + 1)


def dspring(t, start_time, omega, damping_ratio, v0):
    zeta = damping_ratio
    t = t - start_time
    
    if zeta == 1.0:
        c1 = -1.0
        c2 = v0 - omega
        return (c2 - omega * c1 - omega * c2 * t) * np.exp(-omega * t)
    elif zeta > 1:
        s1 = omega * (-zeta + np.sqrt(zeta * zeta - 1))
        s2 = omega * (-zeta - np.sqrt(zeta * zeta - 1))
        c1 = (-s2 - v0) / (s2 - s1)
        c2 = (s1 + v0) / (s2 - s1)
        return c1 * s1 * np.exp(s1 * t) + c2 * s2 * np.exp(s2 * t)
    else:
        a = -omega * zeta
        b = omega * np.sqrt(1 - zeta * zeta)
        c2 = (v0 + a) / b
        theta = np.arctan(c2)
        return np.sqrt(1 + c2 * c2) * np.exp(a * t) * (a * np.cos(b * t + theta + np.pi) - b * np.sin(b * t + theta + np.pi))


def linear(t, start_time, duration):
    t = t - start_time
    y = t / duration
    return np.where(t < 0, np.zeros_like(t), np.where(t > duration, np.ones_like(t), y))


def t_y_from_data(data, start_value, end_value):
    ts = []
    ys = []
    for (t, y) in data:
        ts.append(t)
        ys.append(y)
    return np.array(ts), (np.array(ys) - start_value) / (end_value - start_value)


def data_compare(data1, data2):
    print(len(data1), len(data2))
    error = 0
    for (t1, t2) in zip(data1, data2):
        y1 = t1[1]
        y2 = t2[1]
        error += abs(y1 - y2)
        
    error /= min(len(data1), len(data2))
    return error


def y_smse(y_array1, y_array2):
    """The square root of mean squared error"""
    count = 0
    error = 0
    for (y1, y2) in zip(y_array1, y_array2):
        error += (y1 - y2) ** 2
        count += 1
        
    if count == 0:
        return 0
    else:
        mean = error / count
        return np.sqrt(mean)


def stiffness_damping(parameters, mass=1.0):
    _, omega, damping_ratio, _ = parameters
    stiffness = mass * omega ** 2
    damping = damping_ratio * 2 * np.sqrt(stiffness * mass)
    return stiffness, damping


def omega_zeta(stiffness, damping, mass=1):
    omega = np.sqrt(stiffness / mass)
    zeta = damping / 2 / np.sqrt(stiffness * mass)
    return omega, zeta


def concat(data1, data2, offset):
    data = data2.copy()
    data[:, 0] += offset
    return np.concatenate([data1, data])
