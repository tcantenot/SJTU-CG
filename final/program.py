from shader import *

class Program(object):

    def __init__(self):
        self.shaders = { }
        self.linked = False

        self.shaders[SHADER_STAGE.VERTEX] = []
        self.shaders[SHADER_STAGE.FRAGMENT] = []

    def attachShader(self, shader):
        self.shaders[shader.stage].append(shader)

    def link(self):
        for stage, shaders in self.shaders.items():
            for i, shader in enumerate(shaders):
                if not shader.compiled:
                    print "Failed to link program: {} shader {} \
                        not compiled".format(SHADER_STAGE.name(self.stage).lower(), i)
                    return False

        self.id = glCreateProgram()

        for stage, shaders in self.shaders.items():
            for shader in shaders:
                glAttachShader(self.id, shader.id)

        glLinkProgram(self.id)

        self.linked = True

        for stage, shaders in self.shaders.items():
            for shader in shaders:
                glDetachShader(self.id, shader.id)

    def bind(self):
        glUseProgram(self.id)

    def reloadIfNewer(self):
        reloaded = False
        for stage, shaders in self.shaders.items():
            for shader in shaders:
                reloaded |= shader.reloadIfNewer()

        if reloaded:
            self.link()

        return reloaded
