import timeit


def belapsed(func, *, number=None):
    if number:
        return timeit.timeit(func, number=number) / number
    else:
        timer = timeit.Timer(func)
        n, t = timer.autorange()
        return t / n
