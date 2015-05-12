try:
    import OpenGL.GL as gl
    import OpenGL.GLUT as glut
except ImportError:
    raise ImportError, "Required dependency OpenGL not present"

import time, sys

from scene import Scene, Demo
from mouse import Mouse
from utils import now


def display(scene):

    def _display():
        scene.init()
        updated = scene.render(mouse=Mouse(0, 0))
        if updated: glut.glutSwapBuffers()

    return _display


lastFrameTime = now()

def nextFrame(fps):

    deltaFrame = 1.0 / fps

    def _nextFrame():
        global lastFrameTime
        dt = now() - lastFrameTime
        time.sleep(abs(deltaFrame - dt))
        lastFrameTime = now()
        glut.glutPostRedisplay()

    return _nextFrame


def reshape(scene):

    def _reshape(width, height):
        scene.resize((width, height))
        gl.glViewport(0, 0, width, height)

    return _reshape


def keyboard(key, x, y):
    if key == '\033':
        sys.exit( )


if __name__ == "__main__":

    w, h = 512, 512
    scene = Demo((w, h))

    glut.glutInit()
    glut.glutInitDisplayMode(glut.GLUT_DOUBLE | glut.GLUT_RGBA)
    glut.glutCreateWindow('Hello world!')
    glut.glutReshapeWindow(w, h)
    glut.glutReshapeFunc(reshape(scene))
    glut.glutDisplayFunc(display(scene))
    glut.glutKeyboardFunc(keyboard)
    glut.glutIdleFunc(nextFrame(60));
    glut.glutMainLoop()
