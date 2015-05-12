import time

def now():
    return time.time()

# See: http://stackoverflow.com/a/1695250
def enum(*sequential, **named):
    enums = dict(zip(sequential, range(len(sequential))), **named)
    reverse = dict((value, key) for key, value in enums.iteritems())
    enums['name'] = reverse
    return type('Enum', (), enums)
