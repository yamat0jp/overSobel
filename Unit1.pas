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
    FileOpen2: TFileOpen;
    FileOpen3: TFileOpen;
    procedure Action1Execute(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
    procedure FileOpen2Accept(Sender: TObject);
    procedure FileOpen3Accept(Sender: TObject);
  private
    { Private êÈåæ }
  public
    { Public êÈåæ }
    procedure proc(src1, src2: PIplImage);
    procedure subproc;
    procedure toBitmap(img: PIplImage);
    procedure Add(src, dst: PIplImage);
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

// è¨Ç≥Ç¢ïîï™ÇÃè¡ãé
function remove_small_objects(img_in: PIplImage; size: integer): PIplImage;
var
  img_out: PIplImage;
  s_storage: pCvMemStorage;
  s_contours: pCvSeq;
  black, white: TCvScalar;
  area: double;
begin
  img_out := cvCloneImage(img_in);
  s_storage := cvCreateMemStorage(0);
  s_contours := nil;
  black := CV_RGB(0, 0, 0);
  white := CV_RGB(255, 255, 255);
  s_contours := AllocMem(SizeOf(TCvSeq));
  cvClearMemStorage(s_storage);
  cvFindContours(img_in, s_storage, @s_contours, SizeOf(TCvContour),
    CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
  while (s_contours <> nil) do
  begin
    area := cvContourArea(s_contours, CV_WHOLE_SEQ);
    if abs(area) <= size then
      cvDrawContours(img_out, s_contours, black, black, -1, CV_FILLED, 8,
        cvPoint(0, 0))
    else
      cvDrawContours(img_out, s_contours, white, white, -1, CV_FILLED, 8,
        cvPoint(0, 0));
    s_contours := s_contours.h_next;
  end;
  cvReleaseMemStorage(s_storage);
  s_contours := nil;
  FreeMem(s_contours, SizeOf(TCvSeq));
  result := img_out;
end;

procedure TForm2.Action1Execute(Sender: TObject);
var
  name: AnsiString;
  img, dst1, dst2: PIplImage;
begin
  name := AnsiString(FileOpen1.Dialog.FileName);
  img := cvLoadImage(PAnsiChar(name), CV_LOAD_IMAGE_GRAYSCALE);
  if not Assigned(img) then
    Exit;
  dst1 := cvCloneImage(img);
  dst2 := cvCloneImage(img);
  try
    cvSmooth(img, dst1, CV_GAUSSIAN, 15, 15);
    cvSmooth(img, dst2, CV_GAUSSIAN, 3, 3);
    proc(dst1, dst2)
  finally
    cvReleaseImage(img);
    cvReleaseImage(dst1);
    cvReleaseImage(dst2);
  end;
end;

procedure TForm2.Add(src, dst: PIplImage);
var
  wid, ch, k: integer;
begin
  wid := src^.widthStep;
  ch := src^.nChannels;
  for var i := 0 to src^.height - 1 do
    for var j := 0 to src^.width - 1 do
      if src^.imageData[i * wid + j * ch] > 10 then
      begin
        k := i * wid + j * ch;
        dst^.imageData[k] := 0;
        dst^.imageData[k + 1] := 0;
        dst^.imageData[k + 2] := 255;
      end;
end;

procedure TForm2.FileOpen1Accept(Sender: TObject);
begin
  {
    Action1Execute(Sender);
    subproc; }
  Action1Execute(nil);
end;

procedure TForm2.FileOpen2Accept(Sender: TObject);
var
  src, dst: PIplImage;
  seq: pCvSeq;
  mem: pCvMemStorage;
  name: AnsiString;
  r: TCvRect;
begin
  name := AnsiString(FileOpen2.Dialog.FileName);
  src := cvLoadImage(PAnsiChar(name), CV_LOAD_IMAGE_GRAYSCALE);
  if not Assigned(src) then
    Exit;
  dst := cvCloneImage(src);
  mem := cvCreateMemStorage;
  seq := AllocMem(SizeOf(TCvSeq));
  cvClearMemStorage(mem);
  try
    cvFindContours(src, mem, seq, SizeOf(TCvContour), CV_RETR_LIST,
      CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
    for var i := 0 to seq^.total - 1 do
    begin
      r := cvBoundingRect(seq, i);
      cvRectAngle(dst, cvPoint(r.x, r.y), cvPoint(r.x + r.width,
        r.y + r.height), cvSCalar(255, 255, 0, 0), 2, 8, 0);
    end;
    toBitmap(dst);
  finally
    cvReleaseImage(src);
    cvReleaseImage(dst);
    cvReleaseMemStorage(mem);
    FreeMem(seq, SizeOf(TCvSeq));
  end;
end;

procedure TForm2.FileOpen3Accept(Sender: TObject);
var
  src, dst: PIplImage;
  name: AnsiString;
begin
  name := AnsiString(FileOpen3.Dialog.FileName);
  src := cvLoadImage(PAnsiChar(name), CV_LOAD_IMAGE_GRAYSCALE);
  if not Assigned(src) then
    Exit;
  dst := cvCloneImage(src);
  try
    cvThreShold(src, dst, 160, 255, CV_THRESH_BINARY);
    toBitmap(dst);
  finally
    cvReleaseImage(src);
    cvReleaseImage(dst);
  end;
end;

procedure TForm2.proc(src1, src2: PIplImage);
var
  bmp: TBitmap;
  tmp: PIplImage;
begin
  tmp := cvCloneImage(src1);
  bmp := TBitmap.Create;
  try
    cvAbsDiff(src1, src2, tmp);
    cvThreShold(tmp, tmp, 10, 255, CV_THRESH_BINARY);
    tmp := remove_small_objects(tmp, 100);
    bmp.PixelFormat := pf24bit;
    IplImage2Bitmap(tmp, bmp);
    Image1.Picture.Assign(bmp);
  finally
    bmp.Free;
    cvReleaseImage(tmp);
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

procedure TForm2.toBitmap(img: PIplImage);
var
  bmp: TBitmap;
begin
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf24bit;
    IplImage2Bitmap(img, bmp);
    Image1.Picture.Assign(bmp);
  finally
    bmp.Free;
  end;
end;

end.
