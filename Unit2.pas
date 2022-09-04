unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.jpeg,
  Vcl.ExtCtrls, Vcl.ExtDlgs;

type
  TRGBArray = array [Word] of TRGBTriple;

  TForm2 = class(TForm)
    Image1: TImage;
    Button1: TButton;
    Button2: TButton;
    OpenPictureDialog1: TOpenPictureDialog;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private êÈåæ }
  public
    { Public êÈåæ }
    bmp, back: TBitmap;
    procedure GrayScale(bmp: TBitmap);
    procedure Gaussian(bmp: TBitmap);
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
var
  p1, p2: ^TRGBArray;
  color: Byte;
begin
  GrayScale(back);
  bmp.Assign(back);
  Gaussian(back);
  for var i := 0 to back.Height - 1 do
  begin
    p1 := back.ScanLine[i];
    p2 := bmp.ScanLine[i];
    for var j := 0 to back.Width - 1 do
    begin
      color := p1[j].rgbtBlue - p2[j].rgbtBlue;
      p2[j].rgbtBlue := color;
      p2[j].rgbtGreen := color;
      p2[j].rgbtRed := color;
    end;
  end;
  FormPaint(Sender);
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    Image1.Picture.LoadFromFile(OpenPictureDialog1.FileName);
    back.Assign(Image1.Picture.Graphic);
  end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  back := TBitmap.Create;
  back.Assign(Image1.Picture.Graphic);
  back.PixelFormat := pf24bit;
  bmp := TBitmap.Create;
  bmp.Assign(Image1.Picture.Graphic);
  bmp.PixelFormat := pf24bit;
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  back.Free;
  bmp.Free;
end;

procedure TForm2.FormPaint(Sender: TObject);
begin
  Canvas.Draw(0, 0, bmp);
end;

procedure TForm2.Gaussian(bmp: TBitmap);
var
  p1, p2, p3: ^TRGBArray;
  color, c1, c2, c3: Byte;
begin
  for var i := 0 to back.Height - 3 do
  begin
    p1 := back.ScanLine[i];
    p2 := back.ScanLine[i + 1];
    p3 := back.ScanLine[i + 2];
    for var j := 1 to back.Width - 2 do
    begin
      c1 := (p1[j - 1].rgbtBlue + p1[j + 1].rgbtBlue + p3[j - 1].rgbtBlue +
        p3[j + 1].rgbtBlue) * 2 div 16;
      c2 := (p1[j].rgbtBlue + p2[j - 1].rgbtBlue + p2[j + 1].rgbtBlue +
        p3[j].rgbtBlue) * 2 div 16;
      c3 := p2[j].rgbtBlue * 2 div 16;
      color := c1 + c2 + c3;
      p2[j].rgbtBlue := color;
      p2[j].rgbtGreen := color;
      p2[j].rgbtRed := color;
    end;
  end;
end;

procedure TForm2.GrayScale(bmp: TBitmap);
const
  R = 0.29891;
  G = 0.58661;
  B = 0.11448;
var
  p: ^TRGBArray;
  gray: Byte;
begin
  for var i := 0 to back.Height - 1 do
  begin
    p := back.ScanLine[i];
    for var j := 0 to back.Width - 1 do
    begin
      gray := Round(p[j].rgbtRed * R + p[j].rgbtGreen * G + p[j].rgbtBlue * B);
      p[j].rgbtBlue := gray;
      p[j].rgbtGreen := gray;
      p[j].rgbtRed := gray;
    end;
  end;
end;

end.
