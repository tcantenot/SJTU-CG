try:
    import wx
except ImportError:
    raise ImportError, "Required dependency wx not present"


class SceneTweaker(wx.Dialog):

    def __init__(self, scene=None, *args, **kwargs):
        super(SceneTweaker, self).__init__(*args, **kwargs)

        self.scene = kwargs["scene"] if "scene" in kwargs else None

        self.InitUI()


    def InitUI(self):

        panel = wx.Panel(self)

        sb = wx.StaticBox(panel, label="Tweak values")
        sizer = wx.StaticBoxSizer(sb, wx.VERTICAL)

        self.slider1 = wx.Slider(panel,
            value=100.0, minValue=1.0, maxValue=100.0,
            style=wx.SL_HORIZONTAL
        )

        self.slider2 = wx.Slider(panel,
            value=100.0, minValue=1.0, maxValue=100.0,
            style=wx.SL_HORIZONTAL
        )

        self.slider3 = wx.Slider(panel,
            value=100.0, minValue=1.0, maxValue=100.0,
            style=wx.SL_HORIZONTAL
        )

        self.slider4 = wx.Slider(panel,
            value=100.0, minValue=1.0, maxValue=100.0,
            style=wx.SL_HORIZONTAL
        )

        self.slider1.Bind(wx.EVT_SCROLL, self.OnSliderScroll)
        self.slider2.Bind(wx.EVT_SCROLL, self.OnSliderScroll)
        self.slider3.Bind(wx.EVT_SCROLL, self.OnSliderScroll)
        self.slider4.Bind(wx.EVT_SCROLL, self.OnSliderScroll)

        self.txt1 = wx.StaticText(panel, label='1.00')
        self.txt2 = wx.StaticText(panel, label='1.00')
        self.txt3 = wx.StaticText(panel, label='1.00')
        self.txt4 = wx.StaticText(panel, label='1.00')

        hbox = wx.BoxSizer(wx.HORIZONTAL)

        fgs = wx.FlexGridSizer(4, 2, 15, 25)

        fgs.AddMany([
            (self.slider1, 1, wx.EXPAND), (self.txt1),
            (self.slider2, 1, wx.EXPAND), (self.txt2),
            (self.slider3, 1, wx.EXPAND), (self.txt3),
            (self.slider4, 1, wx.EXPAND), (self.txt4),
        ])

        fgs.AddGrowableCol(0, 1)

        hbox.Add(fgs, proportion=1, flag=wx.ALL|wx.EXPAND, border=15)

        sizer.Add(hbox, proportion=1, flag=wx.ALL|wx.EXPAND, border=15)

        panel.SetSizer(sizer)

        self.SetSize((300, 250))
        self.Centre()
        self.Show(True)


    def OnSliderScroll(self, e):

        obj = e.GetEventObject()
        val = obj.GetValue()

        if(obj == self.slider1):
            if self.scene: self.scene.setTweakValue(val/100.0, 0)
            self.txt1.SetLabel(str(val/100.0))
        elif(obj == self.slider2):
            if self.scene: self.scene.setTweakValue(val/100.0, 1)
            self.txt2.SetLabel(str(val/100.0))
        elif(obj == self.slider3):
            if self.scene: self.scene.setTweakValue(val/100.0, 2)
            self.txt3.SetLabel(str(val/100.0))
        elif(obj == self.slider4):
            if self.scene: self.scene.setTweakValue(val/100.0, 3)
            self.txt4.SetLabel(str(val/100.0))


