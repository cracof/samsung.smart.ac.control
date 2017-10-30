object frmMain: TfrmMain
  Left = 540
  Top = 395
  Caption = 'Samsung Smart AC Control'
  ClientHeight = 516
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    880
    516)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 239
    Width = 864
    Height = 269
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 0
    ExplicitWidth = 800
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 217
    Height = 169
    Caption = 'AC Device '
    TabOrder = 1
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 50
      Height = 13
      Caption = 'IP Adress:'
    end
    object Label2: TLabel
      Left = 16
      Top = 51
      Width = 61
      Height = 13
      Caption = 'MAC adress:'
    end
    object Label4: TLabel
      Left = 16
      Top = 78
      Width = 57
      Height = 13
      Caption = 'Description:'
    end
    object lbIndicator: TLabel
      Left = 12
      Top = 145
      Width = 75
      Height = 13
      Alignment = taCenter
      AutoSize = False
    end
    object edIP: TEdit
      Left = 83
      Top = 21
      Width = 121
      Height = 21
      MaxLength = 15
      TabOrder = 0
    end
    object edMac: TEdit
      Left = 83
      Top = 48
      Width = 121
      Height = 21
      MaxLength = 17
      TabOrder = 1
    end
    object btnConnect: TButton
      Left = 129
      Top = 133
      Width = 75
      Height = 25
      Caption = 'Connect'
      Default = True
      TabOrder = 2
      OnClick = btnConnectClick
    end
    object btnSSDP: TButton
      Left = 93
      Top = 102
      Width = 111
      Height = 25
      Caption = 'Discover via SSDP'
      TabOrder = 3
      OnClick = btnSSDPClick
    end
    object edDescr: TEdit
      Left = 83
      Top = 75
      Width = 121
      Height = 21
      TabOrder = 4
    end
    object ActivityIndicator1: TActivityIndicator
      Left = 34
      Top = 107
      IndicatorType = aitSectorRing
    end
  end
  object gbDevice: TGroupBox
    Left = 231
    Top = 8
    Width = 642
    Height = 225
    Caption = 'Device '
    Enabled = False
    TabOrder = 2
    object Label3: TLabel
      Left = 16
      Top = 24
      Width = 33
      Height = 13
      Caption = 'Power '
    end
    object Label5: TLabel
      Left = 16
      Top = 113
      Width = 69
      Height = 13
      Caption = 'Temperature: '
    end
    object lbTempNow: TLabel
      Left = 16
      Top = 175
      Width = 185
      Height = 33
      Alignment = taCenter
      AutoSize = False
      Caption = 'current: 00 '#176'C'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object lbTempSet: TLabel
      Left = 207
      Top = 175
      Width = 130
      Height = 33
      Alignment = taCenter
      AutoSize = False
      Caption = 'set: 00 '#176'C'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object lbError: TLabel
      Left = 464
      Top = 175
      Width = 169
      Height = 33
      Alignment = taRightJustify
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Visible = False
    end
    object tgSwitch: TToggleSwitch
      Left = 55
      Top = 22
      Width = 72
      Height = 20
      TabOrder = 0
      OnClick = tgSwitchClick
    end
    object seTemp: TSpinEdit
      Left = 91
      Top = 110
      Width = 46
      Height = 22
      MaxValue = 30
      MinValue = 16
      TabOrder = 1
      Value = 16
      OnExit = seTempExit
    end
    object cbxWiFi: TCheckBox
      Left = 16
      Top = 60
      Width = 97
      Height = 17
      Caption = 'WiFi connection'
      Enabled = False
      TabOrder = 2
    end
    object cbxInternet: TCheckBox
      Left = 16
      Top = 83
      Width = 97
      Height = 17
      Caption = 'Internet conn.'
      Enabled = False
      TabOrder = 3
    end
    object Panel1: TPanel
      Left = 150
      Top = 20
      Width = 123
      Height = 149
      Padding.Left = 8
      Padding.Top = 10
      TabOrder = 4
      object Label6: TLabel
        Left = 9
        Top = 11
        Width = 113
        Height = 13
        Align = alTop
        Caption = 'Operation mode:'
        ExplicitWidth = 81
      end
      object rbFMAuto: TRadioButton
        Left = 16
        Top = 30
        Width = 49
        Height = 17
        Caption = 'Auto'
        TabOrder = 0
        OnClick = rbFMAutoClick
      end
      object rbFMCool: TRadioButton
        Left = 16
        Top = 53
        Width = 57
        Height = 17
        Caption = 'Cool'
        TabOrder = 1
        OnClick = rbFMCoolClick
      end
      object rbFMDry: TRadioButton
        Left = 16
        Top = 76
        Width = 58
        Height = 17
        Caption = 'Dry'
        TabOrder = 2
        OnClick = rbFMDryClick
      end
      object rbFMWind: TRadioButton
        Left = 16
        Top = 99
        Width = 42
        Height = 17
        Caption = 'Wind'
        TabOrder = 3
        OnClick = rbFMWindClick
      end
      object rbFMHeat: TRadioButton
        Left = 16
        Top = 122
        Width = 49
        Height = 17
        Caption = 'Heat'
        TabOrder = 4
        OnClick = rbFMHeatClick
      end
    end
    object cbxSPI: TCheckBox
      Left = 16
      Top = 135
      Width = 41
      Height = 17
      Caption = 'SPI'
      TabOrder = 5
      OnClick = cbxSPIClick
    end
    object Panel2: TPanel
      Left = 407
      Top = 20
      Width = 228
      Height = 149
      Padding.Left = 8
      Padding.Top = 10
      TabOrder = 6
      object Label7: TLabel
        Left = 9
        Top = 11
        Width = 218
        Height = 13
        Align = alTop
        Caption = 'Convenient mode:'
        ExplicitLeft = 25
      end
      object rbCMOff: TRadioButton
        Left = 16
        Top = 30
        Width = 65
        Height = 17
        Caption = 'Off'
        TabOrder = 0
        OnClick = rbCMOffClick
      end
      object rbCMQuiet: TRadioButton
        Left = 16
        Top = 53
        Width = 73
        Height = 17
        Caption = 'Quiet'
        TabOrder = 1
        OnClick = rbCMQuietClick
      end
      object rbCMSleep: TRadioButton
        Left = 16
        Top = 76
        Width = 81
        Height = 17
        Caption = 'Sleep'
        TabOrder = 2
        OnClick = rbCMSleepClick
      end
      object rbCMSmart: TRadioButton
        Left = 16
        Top = 99
        Width = 73
        Height = 17
        Caption = 'Smart'
        TabOrder = 3
        OnClick = rbCMSmartClick
      end
      object rbCMSoftCool: TRadioButton
        Left = 16
        Top = 122
        Width = 81
        Height = 17
        Caption = 'Soft Cool'
        TabOrder = 4
        OnClick = rbCMSoftCoolClick
      end
      object rbCMTurboMode: TRadioButton
        Left = 128
        Top = 30
        Width = 81
        Height = 17
        Caption = 'Turbo mode'
        TabOrder = 5
        OnClick = rbCMTurboModeClick
      end
      object rbCMWindMode1: TRadioButton
        Left = 128
        Top = 53
        Width = 81
        Height = 17
        Caption = 'Wind mode 1'
        TabOrder = 6
        OnClick = rbCMWindMode1Click
      end
      object rbCMWindMode2: TRadioButton
        Left = 128
        Top = 76
        Width = 81
        Height = 17
        Caption = 'Wind mode 2'
        TabOrder = 7
        OnClick = rbCMWindMode2Click
      end
      object rbCMWindMode3: TRadioButton
        Left = 128
        Top = 99
        Width = 89
        Height = 17
        Caption = 'Wind mode 3'
        TabOrder = 8
        OnClick = rbCMWindMode3Click
      end
    end
    object Panel3: TPanel
      Left = 278
      Top = 20
      Width = 123
      Height = 149
      Padding.Left = 8
      Padding.Top = 10
      TabOrder = 7
      object Label8: TLabel
        Left = 9
        Top = 11
        Width = 113
        Height = 13
        Align = alTop
        Caption = 'Wind mode:'
        ExplicitWidth = 57
      end
      object rbWLAuto: TRadioButton
        Left = 16
        Top = 30
        Width = 49
        Height = 17
        Caption = 'Auto'
        TabOrder = 0
        OnClick = rbWLAutoClick
      end
      object rbWLLow: TRadioButton
        Left = 16
        Top = 53
        Width = 57
        Height = 17
        Caption = 'Low'
        TabOrder = 1
        OnClick = rbWLLowClick
      end
      object rbWLMid: TRadioButton
        Left = 16
        Top = 76
        Width = 58
        Height = 17
        Caption = 'Midium'
        TabOrder = 2
        OnClick = rbWLMidClick
      end
      object rbWLHigh: TRadioButton
        Left = 16
        Top = 99
        Width = 42
        Height = 17
        Caption = 'High'
        TabOrder = 3
        OnClick = rbWLHighClick
      end
    end
  end
  object btnStatus: TButton
    Left = 137
    Top = 194
    Width = 75
    Height = 25
    Caption = 'btnStatus'
    TabOrder = 3
    OnClick = btnStatusClick
  end
  object Button1: TButton
    Left = 56
    Top = 194
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 4
    OnClick = Button1Click
  end
end
