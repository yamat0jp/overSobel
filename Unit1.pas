unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ocv.comp.Types, ocv.comp.ImageOperation,
  ocv.comp.Source, ocv.comp.View,
  ocv.highgui_c,
  ocv.core_c,
  ocv.core.types_c,
  ocv.imgproc_c,
  ocv.imgproc.types_c,
  ocv.utils,
  uResourcePaths, System.Actions, Vcl.ActnList, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ExtCtrls, Vcl.StdActns;

type
  TForm2 = class(TForm)
    ActionManager1: TActionManager;
    ActionToolBar1: TActionToolBar;
    Action1: TAction;
    Image1: TImage;
    FileOpen1: TFileOpen;
    procedure Action1Execute(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
  private
    { Private êÈåæ }
  public
    { Public êÈåæ }
    procedure proc(src1, src2: PIplImage);
    procedure subproc;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Action1Execute(Sender: TObject);
var
  name: AnsiString;
  img, dst1, dst2: PIplImage;
begin
  name := AnsiString(FileOpen1.Dialog.FileName);
  img := cvLoadImage(PAnsiChar(name), CV_LOAD_IMAGE_GRAYSCALE);
  try
    if not Assigned(img) then
      Exit;
    dst1 := cvCloneImage(img);
    dst2 := cvCloneImage(img);
    cvSmooth(img, dst1, CV_GAUSSIAN, 15, 15);
    cvSmooth(img, dst2, CV_GAUSSIAN, 3, 3);
    proc(dst1, dst2);
  finally
    cvReleaseImage(img);
    cvReleaseImage(dst1);
    cvReleaseImage(dst2);
  end;
end;

procedure TForm2.FileOpen1Accept(Sender: TObject);
begin
  Action1Execute(Sender);
  subproc;
end;

procedure TForm2.proc(src1, src2: PIplImage);
type
  TRGBArray = array [Word] of TRGBTriple;
var
  bmp1, bmp2, tmp: TBitmap;
  p1, p2, q: ^TRGBArray;
  gray: Byte;
begin
  bmp1 := TBitmap.Create;
  bmp2 := TBitmap.Create;
  tmp := TBitmap.Create;
  try
    bmp1.PixelFormat := pf24bit;
    bmp2.PixelFormat := pf24bit;
    tmp.PixelFormat := pf24bit;
    IplImage2Bitmap(src1, bmp1);
    IplImage2Bitmap(src2, bmp2);
    tmp.Assign(bmp1);
    for var i := 0 to bmp1.Height - 1 do
    begin
      p1 := bmp1.ScanLine[i];
      p2 := bmp2.ScanLine[i];
      q := tmp.ScanLine[i];
      for var j := 0 to bmp1.Width - 1 do
      begin
        gray := -p1[j].rgbtBlue + p2[j].rgbtBlue;
        q[j].rgbtBlue := gray;
        q[j].rgbtGreen := gray;
        q[j].rgbtRed := gray;
      end;
    end;
    Image1.Picture.Assign(tmp);
  finally
    bmp1.Free;
    bmp2.Free;
    tmp.Free;
  end;
end;

procedure TForm2.subproc;
var
  src, dst: PIplImage;
  bmp: TBitmap;
begin
  bmp := Image1.Picture.Bitmap;
  bmp.PixelFormat := pf24bit;
  src := BitmapToIplImage(bmp);
  dst := cvCloneImage(src);
  try
    cvSmooth(src, dst, CV_GAUSSIAN, 3, 3);
    IplImage2Bitmap(dst, bmp);
  finally
    cvReleaseImage(src);
    cvReleaseImage(dst);
  end;
end;

end.
