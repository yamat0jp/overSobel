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

// �����������̏���
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

    // �摜�̃T�C�Y�ݒ� �J�����ɂ���Ēl���C�����܂�           �ǉ�
    cvSetCaptureProperty(Capture, CV_CAP_PROP_FRAME_WIDTH, 320);
    cvSetCaptureProperty(Capture, CV_CAP_PROP_FRAME_HEIGHT, 240);

    storage    := cvCreateMemStorage(0);

    // Create a new named window with title: result  �ǉ�
    cvNamedWindow('Output Image', CV_WINDOW_AUTOSIZE);
    // frame �� �擾�����܂ő҂��܂�  �ǉ�
    while frame = nil do begin
      frame    := cvQueryFrame(capture);
      key := cvwaitkey(100);      // cvNamedWindow�����s���Ă����Ȃ���cvwaitkey�����삵�܂���
      if key = 27 then begin
        cvReleaseCapture(capture);
        cvReleaseMemStorage(storage);
        cvDestroyAllWindows();
        Halt(1);
      end;
    end;
    // greyimage�̈�쐬
    frame_grey := cvCreateImage(cvSize(frame^.width, frame^.height), IPL_DEPTH_8U, 1);
    writeln('>MotionDetect start');
    writeln('>�摜�\����ʑI���@ESC �L�[�ŏI��');
    while true do
    begin
      frame := cvQueryFrame(capture);                         // ��t���[�����o��
      if frame = nil then
        break;
      cvCvtColor(frame, frame_grey, CV_RGB2GRAY);             // �O���[�摜�ϊ�
      if first then
      begin
        difference_img := cvCloneImage(frame_grey);           // �N���[���̈�̍쐬
        oldframe_grey  := cvCloneImage(frame_grey);
        cvConvertScale(frame_grey, oldframe_grey, 1.0, 0.0);  // ���{�R�s�[
        first := false;
      end;
      cvAbsDiff(oldframe_grey, frame_grey, difference_img);   // �����v�Z
      cvSmooth(difference_img, difference_img, CV_BLUR);      // ������
      // Threshold�̒l 25 ��ύX����Ɗ��x���ς��܂�
      cvThreshold(difference_img, difference_img, 25, 255, CV_THRESH_BINARY);
      // �������摜(100�ȉ�)�̍폜
      difference_img := remove_small_objects(difference_img, 100);

      contours := AllocMem(SizeOf(TCvSeq));
      cvClearMemStorage(storage);
      // �֊s�̒��o
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
    // �������[�̉��
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
