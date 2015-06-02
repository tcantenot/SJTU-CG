import threading


class CommandWorker:
    """ Worker class used to process a queue of commands """

    def __init__(self, queue):
        self._queue = queue

    def run(self):
        """ Run all the commands in the queue """
        while not self._queue.empty():
            command = self._queue.dequeue()
            self._execute(command)

    def _execute(self, command):
        """ Execute a command """
        (func, args, kwargs) = command
        func(*args, **kwargs)


    @staticmethod
    def packCall(func, args, kwargs):
        """ Pack the arguments of a command """
        return (func, args, kwargs)


class CommandQueue:
    """ Thread-safe queue holding commmands """

    def __init__(self):
        self._queue = self.Queue()

    def enqueue(self, func, args=[], kwargs={}, highPriority=False):
        """ Enqueue a command """
        command = CommandWorker.packCall(func, args, kwargs)
        self._queue.enqueue(command, highPriority)

    def empty(self):
        """ Tell whether the queue is empty """
        return self._queue.empty()

    def dequeue(self):
        """ Dequeue a command """
        return self._queue.dequeue()

    def flush(self):
        """ Remove all commands from the queue """
        while not self._queue.empty():
            self._queue.dequeue()


    class Queue:
        """ Internal queue implementation """
        def __init__(self):
            self._list = []
            self._condition = threading.Condition()

        def enqueue(self, command, highPriority):
            """ Enqueue a command """
            with self._condition:
                if highPriority:
                    self._list.insert(0, command)
                else:
                    self._list.append(command)
                self._condition.notify()

        def empty(self):
            """ Tell whether the queue is empty """
            with self._condition:
                return len(self._list) == 0

        def dequeue(self):
            """ Dequeue a command """
            with self._condition:
                while self.empty():
                    self._condition.wait()
                return self._list.pop(0)

