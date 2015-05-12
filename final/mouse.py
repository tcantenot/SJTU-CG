class Mouse(object):
    """ Mouse object """
    def __init__(self, x, y, cx, cy):
        self.x, self.y = x, y
        self.clickx, self.clicky = cx, cy
