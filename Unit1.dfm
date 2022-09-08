object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 454
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 23
    Width = 635
    Height = 431
    Align = alClient
    Proportional = True
    Stretch = True
    ExplicitLeft = 392
    ExplicitWidth = 243
  end
  object ActionToolBar1: TActionToolBar
    Left = 0
    Top = 0
    Width = 635
    Height = 23
    ActionManager = ActionManager1
    Caption = 'ActionToolBar1'
    Color = clMenuBar
    ColorMap.DisabledFontColor = 10461087
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clWhite
    ColorMap.SelectedFontColor = clWhite
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Spacing = 0
  end
  object ActionManager1: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Action = FileOpen1
            ImageIndex = 7
            ShortCut = 16463
          end>
        ActionBar = ActionToolBar1
      end>
    Left = 312
    Top = 232
    StyleName = 'Platform Default'
    object Action1: TAction
      Caption = 'Action1'
      OnExecute = Action1Execute
    end
    object FileOpen1: TFileOpen
      Category = #12501#12449#12452#12523
      Caption = #38283#12367'(&O)...'
      Dialog.Filter = 'JPG|*.jpg;*.jpeg'
      Hint = #38283#12367'|'#26082#23384#12398#12501#12449#12452#12523#12434#38283#12365#12414#12377
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = FileOpen1Accept
    end
  end
end
