import datetime, time

def now():
    """ Get the current time in seconds """
    return time.time()

def hms():
    """ Get the current time in string in 'H:M:S' format """
    return datetime.datetime.strftime(datetime.datetime.now(), "%H:%M:%S")

# See: http://stackoverflow.com/a/1695250
def enum(*sequential, **named):
    """ Build an 'enum' """
    enums = dict(zip(sequential, range(len(sequential))), **named)
    reverse = dict((value, key) for key, value in enums.iteritems())
    enums['name'] = reverse
    return type('Enum', (), enums)
