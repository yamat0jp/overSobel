program Project2;

{$APPTYPE CONSOLE}
{$POINTERMATH ON}
{$R *.res}

uses
  System.SysUtils,
  System.Math,
  ocv.highgui_c,
  ocv.core_c,
  ocv.core.types_c,
  ocv.imgproc_c,
  ocv.imgproc.types_c;

{$DEFINE RECT} //- using cvBoundingRect - work correctly
                  // - not defined RECT - using cvMinAreaRect2

var
  storage       : pCvMemStorage = nil;
  capture       : pCvCapture    = nil;
  frame         : pIplImage     = nil;
  frame_grey    : pIplImage     = nil;
  difference_img: pIplImage     = nil;
  oldframe_grey : pIplImage     = nil;
  contours      : pCvSeq        = nil;
  c             : pCvSeq        = nil;
{$IFDEF RECT}
  rect: TCvRect;
{$ELSE}
  rect2d: TCvBox2D;
{$ENDIF}
  key  : integer;
  first: boolean = true;

// 小さい部分の消去
function remove_small_objects(img_in: pIplImage; size: integer): pIplImage;
var
  img_out     : pIplImage;
  s_storage   : pCvMemStorage;
  s_contours  : pCvSeq;
  black, white: TCvScalar;
  area        : double;
begin
  img_out    := cvCloneImage(img_in);
  s_storage  := cvCreateMemStorage(0);
  s_contours := nil;
  black      := CV_RGB(0, 0, 0);
  white      := CV_RGB(255, 255, 255);
  s_contours := AllocMem(SizeOf(TCvSeq));
  cvClearMemStorage(s_storage);
  cvFindContours(img_in, s_storage, @s_contours, SizeOf(TCvContour), CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
  while (s_contours <> nil) do
  begin
    area := cvContourArea(s_contours, CV_WHOLE_SEQ);
    if abs(area) <= size then
      cvDrawContours(img_out, s_contours, black, black, -1, CV_FILLED, 8, cvPoint(0, 0))
    else
      cvDrawContours(img_out, s_contours, white, white, -1, CV_FILLED, 8, cvPoint(0, 0));
    s_contours := s_contours.h_next;
  end;
  cvReleaseMemStorage(s_storage);
  s_contours := nil;
  FreeMem(s_contours, SizeOf(TCvSeq));
  result := img_out;
end;

begin
  try
    capture    := cvCreateCameraCapture(0);
    if not Assigned(capture) then
      Halt(1);

    // 画像のサイズ設定 カメラによって値を修正します           追加
    cvSetCaptureProperty(Capture, CV_CAP_PROP_FRAME_WIDTH, 320);
    cvSetCaptureProperty(Capture, CV_CAP_PROP_FRAME_HEIGHT, 240);

    storage    := cvCreateMemStorage(0);

    // Create a new named window with title: result  追加
    cvNamedWindow('Output Image', CV_WINDOW_AUTOSIZE);
    // frame が 取得されるまで待ちます  追加
    while frame = nil do begin
      frame    := cvQueryFrame(capture);
      key := cvwaitkey(100);      // cvNamedWindowを実行しておかないとcvwaitkeyが動作しません
      if key = 27 then begin
        cvReleaseCapture(capture);
        cvReleaseMemStorage(storage);
        cvDestroyAllWindows();
        Halt(1);
      end;
    end;
    // greyimage領域作成
    frame_grey := cvCreateImage(cvSize(frame^.width, frame^.height), IPL_DEPTH_8U, 1);
    writeln('>MotionDetect start');
    writeln('>画像表示画面選択　ESC キーで終了');
    while true do
    begin
      frame := cvQueryFrame(capture);                         // 一フレーム取り出し
      if frame = nil then
        break;
      cvCvtColor(frame, frame_grey, CV_RGB2GRAY);             // グレー画像変換
      if first then
      begin
        difference_img := cvCloneImage(frame_grey);           // クローン領域の作成
        oldframe_grey  := cvCloneImage(frame_grey);
        cvConvertScale(frame_grey, oldframe_grey, 1.0, 0.0);  // 等倍コピー
        first := false;
      end;
      cvAbsDiff(oldframe_grey, frame_grey, difference_img);   // 差分計算
      cvSmooth(difference_img, difference_img, CV_BLUR);      // 平滑化
      // Thresholdの値 25 を変更すると感度が変わります
      cvThreshold(difference_img, difference_img, 25, 255, CV_THRESH_BINARY);
      // 小さい画像(100以下)の削除
      difference_img := remove_small_objects(difference_img, 100);

      contours := AllocMem(SizeOf(TCvSeq));
      cvClearMemStorage(storage);
      // 輪郭の抽出
      cvFindContours(difference_img, storage, @contours, SizeOf(TCvContour), CV_RETR_LIST, CV_CHAIN_APPROX_NONE,
        cvPoint(0, 0));
      c := contours;
      while (c <> nil) do
      begin
{$IFDEF RECT}
        rect := cvBoundingRect(c, 0);
        cvRectangle(frame, cvPoint(rect.x, rect.y), cvPoint(rect.x + rect.width, rect.y + rect.height),
          cvScalar(0, 0, 255, 0), 2, 8, 0);
{$ELSE}
        rect2d := cvMinAreaRect2(c);
        cvRectangle(frame, cvPoint(Round(rect2d.center.x - rect2d.size.width / 2),
          Round(rect2d.center.y - rect2d.size.height / 2)), cvPoint(Round(rect2d.center.x + rect2d.size.width / 2),
          Round(rect2d.center.y + rect2d.size.height / 2)), cvScalar(0, 0, 255, 0), 2, 8, 0);
{$ENDIF}
        c := c.h_next;
      end;
      cvShowImage('Output Image', frame);
      cvShowImage('Difference Image', difference_img);
      cvConvertScale(frame_grey, oldframe_grey, 1.0, 0.0);
      cvClearMemStorage(storage);
      contours := nil;
      c        := nil;
      FreeMem(contours, SizeOf(TCvSeq));
      key := cvWaitKey(33);
      if (key = 27) then
        break;
    end;
    // メモリーの解放
    cvReleaseMemStorage(storage);
    cvReleaseCapture(capture);
    cvReleaseImage(oldframe_grey);
    cvReleaseImage(difference_img);
    cvReleaseImage(frame_grey);
    cvDestroyAllWindows();
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.
