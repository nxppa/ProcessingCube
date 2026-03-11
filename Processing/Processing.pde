float RotX = 0;
float RotY = AngleToRad(90);;
float RotZ = 0;

float VertXOffset = 0;
float VertYOffset = 0;
float VertZOffset = 0;

float CamDist = 0;

float PrevRotX = RotX;
float PrevRotY = RotY;
float PrevRotZ = RotZ;

float PrevCamDist = CamDist;

float MaxDistance = 0;
color[] EdgeColours = {
  color(255, 0, 0),
  color(255, 128, 0),
  color(255, 255, 0),
  color(0, 255, 0),
  color(0, 255, 255),
  color(0, 0, 255),
  color(128, 0, 255),
  color(255, 0, 255),
  color(255, 100, 100),
  color(100, 255, 100),
  color(100, 100, 255),
  color(255, 255, 255)
};
float BaseIntensity = 50;
float ColourDir = 1;
float ColourIntensity = BaseIntensity+1;
Boolean AlwaysRender = true;
Boolean Strobe = false;
Boolean DisplayVerticies = true;

float[][] Verticies;
int[][] Edges;
int Frame = 0;
void setup(){
  size(800, 800);
  String FileName = "Sphere.obj";
  LoadOBJ("../Objects/" + FileName);
}

float AngleToRad(float Angle){
  return Angle * PI / 180;
}
float WrapAngle(float Angle){
  float TwoPI = 2 * PI;
  return (Angle % TwoPI + TwoPI) % TwoPI;
}
float RoundNumber(float Input, float Precision){
  
  double PrecisionDouble = (double) Precision; 
  double Multiplier = Math.pow(10, PrecisionDouble);
  double Increased = Input*Multiplier;
  double Rounded = Math.floor(Increased + 0.5);
  double Converted = Rounded/Multiplier;
  float ConvertedFloat = (float) Converted;
  return ConvertedFloat;
}


float RandomRotX = random(-1, 1);
float RandomRotY = random(-1, 1);

void draw(){
  
  RotX += AngleToRad(RandomRotX);
  RotY += AngleToRad(RandomRotY);

  if (keyPressed){
    switch (key){
      case 'a':
        RotX += AngleToRad(3);
        break;
      case 'd':
        RotX -= AngleToRad(3);
        break;
    }
  }
  Frame += 1;
  if ((RotX == PrevRotX && RotY == PrevRotY && RotZ == PrevRotZ && CamDist == PrevCamDist) && !AlwaysRender) { //if not changed dont redraw
    return;
  }
  //RotX = constrain(RotX, -PI/2, PI/2); // clamp rot
  if (ColourIntensity >= 255 || ColourIntensity <= BaseIntensity){
    ColourDir *= -1;
  }
  ColourIntensity += (ColourDir*3);
  PrevRotX = RotX;
  PrevRotY = RotY;
  PrevCamDist = CamDist;
  background(0);
  float[][] Transformed = new float[Verticies.length][3];
  for (int i = 0; i < Verticies.length; i++) {
    Transformed[i] = TransformVertex(Verticies[i]);
  }

  DrawEdges(Transformed);
  LabelVerticies(Transformed);
}
void LoadOBJ(String FilePath){
  // parse obj file text
  String[] FileLines = loadStrings(FilePath);
  float[][] TempVertices = new float[FileLines.length][3];
  int VertexCount = 0;
  int[][] TempEdgeList = new int[FileLines.length * 4][2];
  int EdgeCount = 0;
  for (int i = 0; i < FileLines.length; i++) {
    String CurrentLine = trim(FileLines[i]);
    if (CurrentLine.startsWith("v ")) {
      String[] Tokens = split(CurrentLine, ' ');
      float x = float(Tokens[1]);
      float y = -float(Tokens[2]);
      float z = float(Tokens[3]);
      TempVertices[VertexCount] = new float[]{x, y, z};
      VertexCount++;
    }
    if (CurrentLine.startsWith("f ")) {
      String[] Tokens = split(CurrentLine, ' ');
      int FaceVertexCount = Tokens.length - 1;
      int[] FaceVertexIndices = new int[FaceVertexCount];
      for (int j = 0; j < FaceVertexCount; j++) {
        String VertexToken = Tokens[j + 1];
        String[] Indices = split(VertexToken, '/');
        int VertexIndex = int(Indices[0]) - 1;
        FaceVertexIndices[j] = VertexIndex;
      }
      for (int j = 0; j < FaceVertexCount; j++) {
        int VertexA = FaceVertexIndices[j];
        int VertexB = FaceVertexIndices[(j + 1) % FaceVertexCount];
        int EdgeMin = min(VertexA, VertexB);
        int EdgeMax = max(VertexA, VertexB);
        TempEdgeList[EdgeCount] = new int[]{EdgeMin, EdgeMax};
        EdgeCount++;
      }
    }
  }

  Verticies = new float[VertexCount][3];
  for (int i = 0; i < VertexCount; i++) {
    Verticies[i] = TempVertices[i];
  }

  //centre model around origin
  float CenterX = 0;
  float CenterY = 0;
  float CenterZ = 0;

  for (int i = 0; i < VertexCount; i++){
    CenterX += Verticies[i][0];
    CenterY += Verticies[i][1];
    CenterZ += Verticies[i][2];
  }

  CenterX /= VertexCount;
  CenterY /= VertexCount;
  CenterZ /= VertexCount;

  for (int i = 0; i < VertexCount; i++) {
    Verticies[i][0] += (-CenterX + VertXOffset);
    Verticies[i][1] += (-CenterY + VertYOffset);
    Verticies[i][2] += (-CenterZ + VertZOffset);
  }

  //find furthest vertex
  for (int i = 0; i < VertexCount; i++){
    float x = Verticies[i][0];
    float y = Verticies[i][1];
    float z = Verticies[i][2];
    float Distance = sqrt(x*x + y*y + z*z);
    if (Distance > MaxDistance) {
      MaxDistance = Distance;
    }
  }
  CamDist = MaxDistance * 1.5;
  Edges = new int[EdgeCount][2];
  for (int i = 0; i < EdgeCount; i++) {
    Edges[i] = TempEdgeList[i];
  }
}

float[] TransformVertex(float[] Vertex) {
  float[] FirstRot = RotateX(Vertex, RotX);
  float[] SecondRot = RotateY(FirstRot, RotY);
  float[] ThirdRot = RotateZ(SecondRot, RotZ);
  return new float[]{
    ThirdRot[0],
    ThirdRot[1],
    ThirdRot[2] + CamDist
  };
}
float[] RotateX(float[] Vertex, float Angle) {
  float x = Vertex[0];
  float y = Vertex[1];
  float z = Vertex[2];
  float MatrixOutputY = y * cos(Angle) - z * sin(Angle);
  float MatrixOutputZ = y * sin(Angle) + z * cos(Angle);
  return new float[]{x, MatrixOutputY, MatrixOutputZ};
}
float[] RotateY(float[] Vertex, float Angle) {
  float x = Vertex[0];
  float y = Vertex[1];
  float z = Vertex[2];
  float MatrixOutputX = x * cos(Angle) - z * sin(Angle);
  float MatrixOutputZ = x * sin(Angle) + z * cos(Angle);
  return new float[]{MatrixOutputX, y, MatrixOutputZ};
}
float[] RotateZ(float[] Vertex, float Angle) {
  float x = Vertex[0];
  float y = Vertex[1];
  float z = Vertex[2];
  float MatrixOutputX = x * cos(Angle) - y * sin(Angle);
  float MatrixOutputY = x * sin(Angle) + y * cos(Angle);
  return new float[]{MatrixOutputX, MatrixOutputY, z};
}
float[] WorldToScreen(float[] Position) {
  float Scale = 200;
  float WorldX = Position[0];
  float WorldY = Position[1];
  float WorldZ = Position[2];
  float ScreenX = (WorldX / WorldZ) * Scale + width / 2;
  float ScreenY = (WorldY / WorldZ) * Scale + height / 2;
  return new float[]{ScreenX, ScreenY};
}
void LabelVerticies(float[][] Verticies){
    for (int i = 0; i < Verticies.length; i++) {
       float[] Vert =  Verticies[i];
       float[] ScreenPoint = WorldToScreen(Vert);
       String x = String.valueOf(RoundNumber(Vert[0], 3));
       String y = String.valueOf(RoundNumber(Vert[1], 3));
       String z = String.valueOf(RoundNumber(Vert[2], 3));

       //text((x + ", " + y + ", " + z), ScreenPoint[0], ScreenPoint[1]);

       textAlign(CENTER);

    }

}
void DrawEdges(float[][] Verts) {
  for (int i = 0; i < Edges.length; i++) {
    int[] Edge = Edges[i];
    if (Edge[0] == -1){
      continue;  
    } 
    float[] WorldPoint1 = Verts[Edge[0]];
    float[] WorldPoint2 = Verts[Edge[1]];
    if (WorldPoint1[2] <= 0 || WorldPoint2[2] <= 0){
        continue;
    }
    float[] ScreenPoint1 = WorldToScreen(WorldPoint1);
    float[] ScreenPoint2 = WorldToScreen(WorldPoint2);
    if (Strobe){
        stroke(color(ColourIntensity,ColourIntensity,ColourIntensity));
    } else {
        stroke(EdgeColours[i % EdgeColours.length]);
    }
    
    line(ScreenPoint1[0], ScreenPoint1[1], ScreenPoint2[0], ScreenPoint2[1]);
  }
}


void mouseDragged() {
  float Sensitivity = 0.01;
  RotY += (mouseX - pmouseX)*Sensitivity;
  RotX += (mouseY - pmouseY)*Sensitivity;
  println(RotX, RotY, CamDist);
}
void mouseWheel(MouseEvent event) {
  CamDist += event.getCount()*MaxDistance/20;
  CamDist = max(0, CamDist);
}
