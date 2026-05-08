object MzAgentIDEFrame: TMzAgentIDEFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  TabOrder = 0
  object TopPanel: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblProjectDir: TLabel
      Left = 16
      Top = 13
      Width = 55
      Height = 15
      Caption = 'Project Dir'
    end
    object edtProjectDir: TEdit
      Left = 78
      Top = 10
      Width = 491
      Height = 23
      TabOrder = 0
      ReadOnly = True
    end
    object btnRefresh: TButton
      Left = 575
      Top = 9
      Width = 55
      Height = 25
      Caption = 'Refresh'
      TabOrder = 1
      OnClick = btnRefreshClick
    end
  end
  object ChatPanel: TPanel
    Left = 0
    Top = 41
    Width = 640
    Height = 318
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 8
    TabOrder = 1
    object ChatMemo: TRichEdit
      Left = 8
      Top = 8
      Width = 624
      Height = 302
      Align = alClient
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Microsoft YaHei UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 359
    Width = 640
    Height = 100
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object InputPanel: TPanel
      Left = 0
      Top = 0
      Width = 555
      Height = 100
      Align = alClient
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 0
      object InputMemo: TMemo
        Left = 8
        Top = 8
        Width = 539
        Height = 84
        Align = alClient
        Font.Charset = GB2312_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnKeyDown = InputMemoKeyDown
      end
    end
    object SendPanel: TPanel
      Left = 555
      Top = 0
      Width = 85
      Height = 100
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      object btnSend: TButton
        Left = 8
        Top = 35
        Width = 70
        Height = 30
        Caption = 'Send'
        Default = True
        TabOrder = 0
        OnClick = btnSendClick
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 459
    Width = 640
    Height = 21
    Panels = <>
    SimplePanel = True
  end
end
