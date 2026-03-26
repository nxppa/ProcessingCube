String BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
import processing.sound.*;
SoundFile Music;
float PosXOffset = 0;
float PosYOffset = 6;
float PosZOffset = 0;

float RotX = 0;
float RotY = 0;
float RotZ = 0;

float CamDist = 0;
float MaxDistance = 0;

float[][] Verticies;
int[][] Faces;
float[][] ZBuffer;

int Frame = 0;
int TriTally = 0;;

String Media;
int[][][] Frames;
int[][] FrameBuffer;
float[][] TexCoords;
int[][] FaceColourRanges = {
  {0, 700, 99, 78, 53}, // table

  {701, 1007, 20, 20, 20}, // left monitor

  {1008, 1020, 30, 30, 30}, //pc
  {1021, 1035, 70, 70, 70}, // keyboard
  {1035, 2000, 20, 20, 20}, // right monitor
};


int VideoWidth;
int VideoHeight;
int FPS;
boolean PrintedTriangleThisFrame = false;
boolean HoldingH = false;
int RenderType = 1;

String[] RenderTypeMap = {
  "Wire Frame",
  "Full Render"
};



long VideoStartTime;
int LastBuiltFrame = -1;

void setup() {
  size(800, 800);
  ZBuffer = new float[width][height];
  LoadOBJ("../Objects/mypcv2.obj");
  LoadMedia();
  VideoStartTime = System.currentTimeMillis();
  pixelDensity(1);
}

float AngleToRad(float Angle) {
  return Angle * PI / 180;
}

void LoadMedia() {
  String Path = "../ProcessingBA/data/media.txt";
  String[] lines = loadStrings(Path);
  Music = new SoundFile(this, "../ProcessingBA/Media/BA.wav");
  //Music.play();
  String[] Header = split(lines[0], ',');
  VideoWidth = int(Header[0]);
  VideoHeight = int(Header[1]);
  FPS = int(Header[2]);
  String[] mediaLines = subset(lines, 1);
  Media = join(mediaLines, "");
  Frames = ParseMedia(Media);
  FrameBuffer = new int[VideoWidth][VideoHeight];
}

int B64Val(char c) {
  if (c == '=') return 0;
  return BASE64.indexOf(c);
}

byte[] DecodeBase64(String s) {
  int b0 = B64Val(s.charAt(0));
  int b1 = B64Val(s.charAt(1));
  int b2 = B64Val(s.charAt(2));
  int b3 = B64Val(s.charAt(3));
  int b4 = B64Val(s.charAt(4));
  int b5 = B64Val(s.charAt(5));
  int b6 = B64Val(s.charAt(6));
  int b7 = B64Val(s.charAt(7));
  int b8 = B64Val(s.charAt(8));
  int b9 = B64Val(s.charAt(9));
  int b10 = B64Val(s.charAt(10));
  int b11 = B64Val(s.charAt(11));
  int c0 = (b0 << 18) | (b1 << 12) | (b2 << 6) | b3;
  int c1 = (b4 << 18) | (b5 << 12) | (b6 << 6) | b7;
  int c2 = (b8 << 18) | (b9 << 12) | (b10 << 6) | b11;
  byte[] out = new byte[8];
  out[0] = (byte)((c0 >> 16) & 255);
  out[1] = (byte)((c0 >> 8) & 255);
  out[2] = (byte)(c0 & 255);
  out[3] = (byte)((c1 >> 16) & 255);
  out[4] = (byte)((c1 >> 8) & 255);
  out[5] = (byte)(c1 & 255);
  out[6] = (byte)((c2 >> 16) & 255);
  out[7] = (byte)((c2 >> 8) & 255);
  return out;
}

int[][][] ParseMedia(String media) {
  String[] FrameStrings = split(media, '|');
  int[][][] Frames = new int[FrameStrings.length][][];
  for (int f = 0; f < FrameStrings.length; f++) {
    if (FrameStrings[f].length() == 0) {
      Frames[f] = new int[0][4];
      continue;
    }
    String[] RectStrings = split(FrameStrings[f], ',');
    int[][] Rectangles = new int[RectStrings.length][4];
    for (int r = 0; r < RectStrings.length; r++) {
      byte[] Decoded = DecodeBase64(RectStrings[r]);
      Rectangles[r][0] = ((Decoded[0] & 255) << 8) | (Decoded[1] & 255);
      Rectangles[r][1] = ((Decoded[2] & 255) << 8) | (Decoded[3] & 255);
      Rectangles[r][2] = ((Decoded[4] & 255) << 8) | (Decoded[5] & 255);
      Rectangles[r][3] = ((Decoded[6] & 255) << 8) | (Decoded[7] & 255);
    }
    Frames[f] = Rectangles;
  }
  return Frames;
}

int CurrentFrame = 0;

void BuildFrameBuffer(int FrameIndex) {
  for (int x = 0; x < VideoWidth; x++) {
    for (int y = 0; y < VideoHeight; y++) {
      FrameBuffer[x][y] = 0;
    }
  }
  int[][] Rectangles = Frames[FrameIndex];
  for (int i = 0; i < Rectangles.length; i++) {
    int rx = Rectangles[i][0];
    int ry = Rectangles[i][1];
    int rw = Rectangles[i][2];
    int rh = Rectangles[i][3];
    for (int x = rx; x < rx + rw; x++) {
      for (int y = ry; y < ry + rh; y++) {
        if (x >= 0 && x < VideoWidth && y >= 0 && y < VideoHeight) {
          FrameBuffer[x][y] = 255;
        }
      }
    }
  }
}

void LoadOBJ(String FilePath) {
  String[] Lines = loadStrings(FilePath);
  float[][] TempVerts = new float[Lines.length][3];
  float[][] TempUVs   = new float[Lines.length][2];
  int VertCount = 0;
  int UVCount = 0;
  int[][] TempFaces = new int[Lines.length * 4][6];
  int FaceCount = 0;
  for (int l = 0; l < Lines.length; l++) {
    String CurrentLine = Lines[l];
    CurrentLine = trim(CurrentLine);
    if (CurrentLine.startsWith("v ")) {
      String[] t = split(CurrentLine, ' ');
      float x = float(t[1]);
      float y = -float(t[2]);
      float z = float(t[3]);
      TempVerts[VertCount] = new float[]{x, y, - z};
      VertCount += 1;
    }
    if (CurrentLine.startsWith("vt ")) {
      String[] t = split(CurrentLine, ' ');
      float u = float(t[1]);
      float v = 1 - float(t[2]);
      TempUVs[UVCount] = new float[]{u, v};
      UVCount += 1;
    }
    if (CurrentLine.startsWith("f ")) {
      String[] t = split(CurrentLine, ' ');
      int n = t.length - 1;
      int[] VertIndex = new int[n];
      for (int i = 0; i < n; i++) {
        String[] parts = split(t[i + 1], '/');
        VertIndex[i] = int(parts[0]) - 1;
      }
      for (int i = 1; i < n - 1; i++) {
        TempFaces[FaceCount] = new int[]{
          VertIndex[0], VertIndex[i], VertIndex[i + 1],
        };
        FaceCount += 1;
      }
    }
  }
  Verticies = new float[VertCount][3];
  for (int i = 0; i < VertCount; i++) {
    Verticies[i] = TempVerts[i];
  }
  TexCoords = new float[UVCount][2];
  for (int i = 0; i < UVCount; i++) {
    TexCoords[i] = TempUVs[i];
  }
  Faces = new int[FaceCount][6];
  for (int i = 0; i < FaceCount; i++) {
    Faces[i] = TempFaces[i];
  }
  for (int i = 0; i < Verticies.length; i++) {
    float[] CurVert = Verticies[i];
    float Distance = sqrt(CurVert[0]*CurVert[0] + CurVert[1]*CurVert[1] + CurVert[2]*CurVert[2]);
    if (Distance > MaxDistance) {
      MaxDistance = Distance;
    }
  }
  CamDist = MaxDistance * 1;
}

float Round(float Value, int Places) {
  float Scale = (float) Math.pow(10, Places);
  return Math.round(Value * Scale) / Scale;
}

float[] TransformVertex(float[] Vert) {

  float X = Vert[0];
  float Y = Vert[1];
  float Z = Vert[2];

  float RotXY = Y * cos(RotX) - Z * sin(RotX);
  float RotXZ = Y * sin(RotX) + Z * cos(RotX);
  float RotXX = X;

  float RotYX = RotXX * cos(RotY) - RotXZ * sin(RotY);
  float RotYZ = RotXX * sin(RotY) + RotXZ * cos(RotY);
  float RotYY = RotXY;

  float FinalX = RotYX;
  float FinalY = RotYY;
  float FinalZ = RotYZ + CamDist;

  return new float[]{FinalX + PosXOffset, FinalY + PosYOffset, FinalZ + PosZOffset};
}
int ToHex(int r, int g, int b) {
  r = constrain(r, 0, 255);
  g = constrain(g, 0, 255);
  b = constrain(b, 0, 255);
  int alpha = 255;
  return alpha * 16777216 + r * 65536 +g * 256 + b;
}
int[] GetFaceColour(int FaceIndex) {
  for (int i = 0; i < FaceColourRanges.length; i++) {
    int start = FaceColourRanges[i][0];
    int end   = FaceColourRanges[i][1];

    if (FaceIndex >= start && FaceIndex <= end) {
      return new int[]{
        FaceColourRanges[i][2],
        FaceColourRanges[i][3],
        FaceColourRanges[i][4]
      };
    }
  }
  return new int[]{255, 0, 255};
}
float[] WorldToScreen(float[] p) {
  float scale = 200;
  float sx = (p[0]/p[2])*scale + width/2;
  float sy = (p[1]/p[2])*scale + height/2;
  return new float[]{sx, sy};
}

void ClearZBuffer() {
  for (int x=0; x<width; x++) {
    for (int y=0; y<height; y++) {
      ZBuffer[x][y]=Float.MAX_VALUE;
    }
  }
}

void ClearBackground(int HexColour) {
  for (int i = 0; i < pixels.length; i++) {
    pixels[i] = HexColour;
  }
}
void draw() {
  //RotX += AngleToRad(1);
  //RotY += AngleToRad(1);
  loadPixels();
  long elapsed = System.currentTimeMillis() - VideoStartTime;
  int TargetFrame = (int)((elapsed / 1000.0) * FPS);
  TargetFrame = TargetFrame % Frames.length;

  if (TargetFrame != LastBuiltFrame) {
    BuildFrameBuffer(TargetFrame);
    LastBuiltFrame = TargetFrame;
    CurrentFrame = TargetFrame;
  }
  ClearBackground(0xFF7A7A7A);
  String BaseText = "Rendering Type: " + RenderTypeMap[RenderType];
  String RotInfo = "Rotation: " + Round(RotX, 2) + ", " + Round(RotY, 2) + ", " + Round(RotZ, 2);
  String OffInfo = "Offset: " + Round(PosXOffset, 2) + ", " + Round(PosYOffset, 2) + ", " + Round(PosZOffset, 2);

  String FacesInfo = "Triangles drawn: " + TriTally;
  String FPSInfo = "FPS: " + (int) Round(frameRate, 0);

  ClearZBuffer();
  float[][] CurrentVerts = new float[Verticies.length][3];
  for (int i=0; i<Verticies.length; i++) {
    CurrentVerts[i]=TransformVertex(Verticies[i]);
  }
  PrintedTriangleThisFrame = false;
  DrawFaces(CurrentVerts);
  updatePixels();
  textSize(30);
  text(BaseText, 20, 30);
  text(RotInfo, 20, 70);
  text(OffInfo, 20, 110);
  text(FacesInfo, 20, 150);
  text(FPSInfo, 20, 180);
}


boolean IsInsideTriangle(float Px, float Py, float[] VertA, float[] VertB, float[] VertC, float InvDenom, float[] OutWeights) {
  float WeightA = ((VertB[1] - VertC[1]) * (Px - VertC[0]) + (VertC[0] - VertB[0]) * (Py - VertC[1])) * InvDenom;
  if (WeightA < 0) {
    return false;
  }
  float WeightB = ((VertC[1] - VertA[1]) * (Px - VertC[0]) + (VertA[0] - VertC[0]) * (Py - VertC[1])) * InvDenom;
  if (WeightB < 0) {
    return false;
  }
  float WeightC = 1 - WeightA - WeightB;
  if (WeightC < 0) {
    return false;
  }
  OutWeights[0] = WeightA;
  OutWeights[1] = WeightB;
  OutWeights[2] = WeightC;
  return true;
}
float GetMinOf(float[] Values) {
  float MinValue = Values[0];
  for (int i = 1; i < Values.length; i++) {
    if (Values[i] < MinValue) {
      MinValue = Values[i];
    }
  }
  return MinValue;
}

float GetMaxOf(float[] Values) {
  float MaxValue = Values[0];
  for (int i = 1; i < Values.length; i++) {
    if (Values[i] > MaxValue) {
      MaxValue = Values[i];
    }
  }
  return MaxValue;
}

int[][] BresLine(int StartX, int StartY, int EndX, int EndY) {
  int DeltaX = Math.abs(EndX - StartX);
  int DeltaY = Math.abs(EndY - StartY);
  int StepX = (StartX < EndX) ? 1 : -1;
  int StepY = (StartY < EndY) ? 1 : -1;
  int Error = DeltaX - DeltaY;
  int MaxPoints = Math.max(DeltaX, DeltaY) + 1;
  int[][] Points = new int[MaxPoints][2];
  int CurrentX = StartX;
  int CurrentY = StartY;
  int Index = 0;
  while (true) {
    Points[Index][0] = CurrentX;
    Points[Index][1] = CurrentY;
    Index++;
    if (CurrentX == EndX && CurrentY == EndY) {
      break;
    }
    int DoubledError = 2 * Error;
    if (DoubledError > -DeltaY) {
      Error -= DeltaY;
      CurrentX += StepX;
    }
    if (DoubledError < DeltaX) {
      Error += DeltaX;
      CurrentY += StepY;
    }
  }
  int[][] Result = new int[Index][2];
  for (int i = 0; i < Index; i++) {
    Result[i][0] = Points[i][0];
    Result[i][1] = Points[i][1];
  }
  return Result;
}
int[] GetColourFromSeed(int[] Seed) {
    int[] Result = new int[3];
    Result[0] = Math.abs(Seed[0] * 31 + Seed[1] * 17) % 256;
    Result[1] = Math.abs(Seed[1] * 29 + Seed[2] * 19) % 256;
    Result[2] = Math.abs(Seed[2] * 23 + Seed[3] * 13) % 256;
    return Result;
}
void DrawLine(int x1, int y1, int x2, int y2) {
  int[][] Line = BresLine(x1, y1, x2, y2);
  for (int i = 0; i < Line.length; i++) {
    int XPos = Line[i][0];
    int YPos = Line[i][1];
    int PixelIndex = YPos * width + XPos;
    if (XPos > 0 && XPos < width && YPos > 0 && YPos < height) {
      int[] Seed = {x1, y1, x2, y2};
      int[] Separated = GetColourFromSeed(Seed);
      int ColourChosen = ToHex(Separated[0], Separated[1], Separated[2]);
      pixels[PixelIndex] = 0xFFFFFFFF;
    }
  }
}
void DrawFaces(float[][] V) {
  TriTally = 0;

  float LightDirectionX = -0.5;
  float LightDirectionY = 1;
  float LightDirectionZ = -1.5;

  float LightLength = sqrt(LightDirectionX * LightDirectionX + LightDirectionY * LightDirectionY + LightDirectionZ * LightDirectionZ);

  LightDirectionX /= LightLength;
  LightDirectionY = -LightDirectionY / LightLength;
  LightDirectionZ /= LightLength;

  int Screen1 = 1322;
  int Screen2 = 1323;

  int Screen3 = 998;
  int Screen4 = 999;

  int FaceCount = Faces.length;

  float[] Weights = new float[3];

  for (int FaceIndex = 0; FaceIndex < FaceCount; FaceIndex++) {
    int[] face = Faces[FaceIndex];

    int VertexIndexA = face[0];
    int VertexIndexB = face[1];
    int VertexIndexC = face[2];

    float[] VertexA = V[VertexIndexA];
    float[] VertexB = V[VertexIndexB];
    float[] VertexC = V[VertexIndexC];

    float DepthA = VertexA[2];
    float DepthB = VertexB[2];
    float DepthC = VertexC[2];

    if (DepthA <= 0 || DepthB <= 0 || DepthC <= 0) {
      continue;
    }

    float[] ScreenA = WorldToScreen(VertexA);
    float[] ScreenB = WorldToScreen(VertexB);
    float[] ScreenC = WorldToScreen(VertexC);

    int ScreenAX = (int)ScreenA[0];
    int ScreenAY = (int)ScreenA[1];

    int ScreenBX = (int)ScreenB[0];
    int ScreenBY = (int)ScreenB[1];

    int ScreenCX = (int)ScreenC[0];
    int ScreenCY = (int)ScreenC[1];
    if (RenderType == 0) {
      // only draw wireframe
      DrawLine(ScreenAX, ScreenAY, ScreenBX, ScreenBY);
      DrawLine(ScreenBX, ScreenBY, ScreenCX, ScreenCY);
      DrawLine(ScreenCX, ScreenCY, ScreenAX, ScreenAY);
      continue;
    }

    if ((ScreenAX < 0 && ScreenBX < 0 && ScreenCX < 0) || (ScreenAX >= width && ScreenBX >= width && ScreenCX >= width) || (ScreenAY < 0 && ScreenBY < 0 && ScreenCY < 0) || (ScreenAY >= height && ScreenBY >= height && ScreenCY >= height)) {
      //if off screen
      continue;
    }
    int MinimumX = max(0, min(ScreenAX, min(ScreenBX, ScreenCX)));
    int MaximumX = min(width - 1, max(ScreenAX, max(ScreenBX, ScreenCX)));

    int MinimumY = max(0, min(ScreenAY, min(ScreenBY, ScreenCY)));
    int MaximumY = min(height - 1, max(ScreenAY, max(ScreenBY, ScreenCY)));

    float denom = (ScreenB[1] - ScreenC[1]) * (ScreenA[0] - ScreenC[0]) + (ScreenC[0] - ScreenB[0]) * (ScreenA[1] - ScreenC[1]);

    if (denom == 0) {
      //if no area skip
      continue;
    }
    if (RenderType == 0) {
      // only draw wireframe
      DrawLine(ScreenAX, ScreenAY, ScreenBX, ScreenBY);
      DrawLine(ScreenBX, ScreenBY, ScreenCX, ScreenCY);
      DrawLine(ScreenCX, ScreenCY, ScreenAX, ScreenAY);
      continue;
    }

    float InverseDenom = 1.0 / denom;

    float[] ModelVertexA = Verticies[VertexIndexA];
    float[] ModelVertexB = Verticies[VertexIndexB];
    float[] ModelVertexC = Verticies[VertexIndexC];

    float EdgeAX = ModelVertexB[0] - ModelVertexA[0];
    float EdgeAY = ModelVertexB[1] - ModelVertexA[1];
    float EdgeAZ = ModelVertexB[2] - ModelVertexA[2];

    float EdgeBX = ModelVertexC[0] - ModelVertexA[0];
    float EdgeBY = ModelVertexC[1] - ModelVertexA[1];
    float EdgeBZ = ModelVertexC[2] - ModelVertexA[2];

    float NormalX = EdgeAY * EdgeBZ - EdgeAZ * EdgeBY;
    float NormalY = EdgeAZ * EdgeBX - EdgeAX * EdgeBZ;
    float NormalZ = EdgeAX * EdgeBY - EdgeAY * EdgeBX;

    float NormalLength = sqrt(NormalX * NormalX + NormalY * NormalY + NormalZ * NormalZ);

    if (NormalLength != 0) {
      NormalX /= NormalLength;
      NormalY /= NormalLength;
      NormalZ /= NormalLength;
    }

    float Brightness = NormalX * LightDirectionX + NormalY * LightDirectionY + NormalZ * LightDirectionZ;

    if (Brightness < 0) {
      Brightness = 0;
    }
    TriTally++;
    Brightness = 0.2 + Brightness * 0.8;

    float InverseA = 1.0 / DepthA;
    float InverseB = 1.0 / DepthB;
    float InverseC = 1.0 / DepthC;

    boolean IsScreenA = (FaceIndex == Screen1 || FaceIndex == Screen2);
    boolean IsScreenB = (FaceIndex == Screen3 || FaceIndex == Screen4);
    boolean IsScreenFace = IsScreenA || IsScreenB;

    float MinPX=0, MaxPX=0, MinPY=0, MaxPY=0;

    if (IsScreenFace) {
      int q1, q2, q3, q4, q5, q6;
      if (IsScreenA) {
        q1 = Faces[Screen1][0];
        q2 = Faces[Screen1][1];
        q3 = Faces[Screen1][2];

        q4 = Faces[Screen2][0];
        q5 = Faces[Screen2][1];
        q6 = Faces[Screen2][2];
      } else {
        q1 = Faces[Screen3][0];
        q2 = Faces[Screen3][1];
        q3 = Faces[Screen3][2];

        q4 = Faces[Screen4][0];
        q5 = Faces[Screen4][1];
        q6 = Faces[Screen4][2];
      }

      float[] PxValues = {
        Verticies[q1][0], Verticies[q2][0], Verticies[q3][0],
        Verticies[q4][0], Verticies[q5][0], Verticies[q6][0]
      };

      float[] PyValues = {
        Verticies[q1][1], Verticies[q2][1], Verticies[q3][1],
        Verticies[q4][1], Verticies[q5][1], Verticies[q6][1]
      };

      MinPX = GetMinOf(PxValues);
      MaxPX = GetMaxOf(PxValues);

      MinPY = GetMinOf(PyValues);
      MaxPY = GetMaxOf(PyValues);
    }

    int[] BaseColor = GetFaceColour(FaceIndex);

    float RedOut = BaseColor[0] * Brightness;
    float GreenOut = BaseColor[1] * Brightness;
    float BlueOut  = BaseColor[2] * Brightness;

    for (int PixelY = MinimumY; PixelY <= MaximumY; PixelY++) {
      float py = PixelY + 0.5;

      for (int PixelX = MinimumX; PixelX <= MaximumX; PixelX++) {
        float px = PixelX + 0.5;
        if (!IsInsideTriangle(px, py, ScreenA, ScreenB, ScreenC, InverseDenom, Weights)) {
          continue;
        }
        if (!PrintedTriangleThisFrame && PixelX == mouseX && PixelY == mouseY) {
          println("over triangle " + FaceIndex);
          PrintedTriangleThisFrame = true;
        }

        float w1 = Weights[0];
        float w2 = Weights[1];
        float w3 = Weights[2];

        float InverseDepth = w1 * InverseA + w2 * InverseB + w3 * InverseC;

        float RealDepthValue = 1.0 / InverseDepth;

        if (RealDepthValue >= ZBuffer[PixelX][PixelY]) {
          continue;
        }

        ZBuffer[PixelX][PixelY] = RealDepthValue;
        int PixelIndex = PixelY * width + PixelX;

        if (IsScreenFace) {
          float PointX2D = w1*ModelVertexA[0] + w2*ModelVertexB[0] + w3*ModelVertexC[0];
          float PointY2D = w1*ModelVertexA[1] + w2*ModelVertexB[1] + w3*ModelVertexC[1];

          float u = (PointX2D - MinPX) / (MaxPX - MinPX);
          float v = (PointY2D - MinPY) / (MaxPY - MinPY);

          int ConvertedWidth  = VideoWidth  - 1;
          int ConvertedHeight = VideoHeight - 1;

          int RawVideoX = (int)(u * ConvertedWidth);
          int RawVideoY = (int)(v * ConvertedHeight);

          int VideoX = constrain(RawVideoX, 0, ConvertedWidth);
          int VideoY = constrain(RawVideoY, 0, ConvertedHeight);

          int val = FrameBuffer[VideoX][VideoY];

          if (IsScreenB) {
            val = FrameBuffer[ConvertedWidth - VideoX][VideoY];
            val = (val == 255) ? 0 : 255;
          }
          pixels[PixelIndex] = (val == 255) ? 0xFFFFFFFF : 0xFF000000;
        } else {
          int r = (int) RedOut;
          int g = (int) GreenOut;
          int b = (int) BlueOut;
          pixels[PixelIndex] = ToHex(r, g, b);
        }
      }
    }
  }
}

void mouseDragged() {
  float RotateScale = 0.01;
  float MoveScale = .1;

  float MouseDeltaX = mouseX - pmouseX;
  float MouseDeltaY = mouseY - pmouseY;

  if (HoldingH) {
    PosXOffset += MouseDeltaX * MoveScale;
    PosYOffset += MouseDeltaY * MoveScale;
  } else {
    RotY += MouseDeltaX * RotateScale;
    RotX += MouseDeltaY * RotateScale;
  }
}
void mouseWheel(MouseEvent Amount) {
  CamDist+=Amount.getCount()*MaxDistance/20;
  CamDist=max(0, CamDist);
}
void keyPressed() {
  if (key == 'h' || key == 'H') {
    HoldingH = true;
  }

  if (key == 'k' || key == 'k') {
    RenderType += 1;
  }
  RenderType %= 2;
}

void keyReleased() {
  if (key == 'h' || key == 'H') {
    HoldingH = false;
  }
}