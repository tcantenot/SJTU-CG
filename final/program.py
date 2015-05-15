from shader import *

class Program(object):
    """ OpenGL program object """

    def __init__(self):
        self.id = 0
        self.shaders = { }
        self.linked = False

        self.shaders[SHADER_STAGE.VERTEX] = []
        self.shaders[SHADER_STAGE.FRAGMENT] = []


    def attachShader(self, shader):
        """ Attach a shader to the program """
        self.shaders[shader.stage].append(shader)


    def link(self):
        """ Create and link the program with the attached shaders """

        # Prefix check: every shader must be compiled
        for stage, shaders in self.shaders.items():
            for i, shader in enumerate(shaders):
                if not shader.compiled:
                    print "Failed to link program: {} shader '{}' not compiled".format(
                        SHADER_STAGE.name[shader.stage].lower(), shader.filename
                    )
                    return False

        # Destroy previous program
        if self.id != 0:
            glDeleteProgram(self.id)
            self.linked = False

        # Create the underlying OpenGL program
        self.id = glCreateProgram()

        # Detach shaders
        for stage, shaders in self.shaders.items():
            for shader in shaders:
                glAttachShader(self.id, shader.id)

        # Link program
        self._link()

        # Detach shaders
        for stage, shaders in self.shaders.items():
            for shader in shaders:
                glDetachShader(self.id, shader.id)


    def bind(self):
        """ Bind program for use """
        glUseProgram(self.id)


    def reloadIfNewer(self):
        """ Reload the program and the shaders if a new version is found """
        reloaded = False
        for stage, shaders in self.shaders.items():
            for shader in shaders:
                reloaded |= shader.reloadIfNewer()
        if reloaded: self.link()
        return reloaded



    def _link(self):
        """ Link program and check log for errors """
        glLinkProgram(self.id)
        self.linked = True
        log = glGetProgramInfoLog(self.id)
        if log != "":
            print "Program log: {}".format(log)
            self.linked = False
        return self.linked
