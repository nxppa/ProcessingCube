int BoardSquares = 8;
float PosXOffset = 0;
float PosYOffset = 0;
float PosZOffset = 0;
int BoardScale = 6;

float RotX = 0;
float RotY = 0;
float RotZ = 0.4;
float CamDist = 0;

float MaxDistance = 0;

float[][] Verticies;
int[][] Faces;
float[][] ZBuffer;
int Frame = 0;
int TriTally = 0;
boolean IsMoving = false;
int AnimPieceStart;
int AnimPieceEnd;
float[] AnimXs;
float[] AnimZs;
int AnimFrame = 0;
int AnimTotalFrames = 20;
int AnimRenderIndex;
int AnimVertStart;
int AnimVertEnd;
float LastX;
float LastZ;
int[][][] Frames;
int[][] PrevValidMoves = null;
int[] BlacklistRender = new int[BoardSquares*BoardSquares];
int[] FacesToColour = {};
Boolean MovingPiece = false;
Boolean WhitesMove = true;
int MovingPieceX = -1;
int MovingPieceY = -1;
int[][] Board = {
  {10, 8, 9, 11, 12, 9, 8, 10},
  {7, 7, 7, 7, 7, 7, 7, 7},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 0, 0, 0},
  {1, 1, 1, 1, 1, 1, 1, 1},
  {4, 2, 3, 5, 6, 3, 2, 4},
};
int[][] KingPositions = {
  {-1, -1},
  {-1, -1},
};
int[][] KnightMoves = {
  {1, 2},
  {2, 1},
  {2, -1},
  {1, -2},
  {-1, -2},
  {-2, -1},
  {-2, 1},
  {-1, 2},
};
int[][] DiagonalDirections = {
  {1, 1},
  {1, -1},
  {-1, -1},
  {-1, 1},
};
int[][] LateralDirections = {
  {0, 1},
  {1, 0},
  {0, -1},
  {-1, 0}
};

int[] Add(int[] C1, int[] C2) {
  int[] Result = new int[2];
  Result[0] = C1[0] + C2[0];
  Result[1] = C1[1] + C2[1];
  return Result;
}

int[][] Combine(int[][] Arr1, int[][] Arr2) {
  int TotalLength = Arr1.length + Arr2.length;
  int[][] NewArr = new int[TotalLength][2];
  for (int i = 0; i < Arr1.length; i++) {
    NewArr[i] = Arr1[i];
  }
  for (int i = 0; i < Arr2.length; i++) {
    int j = Arr1.length + i;
    NewArr[j] = Arr2[i];
  }
  return NewArr;
}
Boolean Equals(int[] C1, int[] C2) {
  return (C1[0] == C2[0]) && (C1[1] == C2[1]);
}
boolean IntInArr(int[] arr, int value) {
  for (int i = 0; i < arr.length; i++) {
    if (arr[i] == value) {
      return true;
    }
  }
  return false;
}
Boolean IsCoordInSet(int[][] Arr, int[] Coord) {
  Boolean Found = false;
  for (int i = 0; i < Arr.length; i++) {
    int[] CurrentCoord = Arr[i];
    if (Equals(CurrentCoord, Coord)) {
      Found = true;
      break;
    }
  }
  return Found;
}
Boolean IsOnboard(int X, int Y) {
  return X >= 0 && Y >= 0 && X <= 7 && Y <= 7;
}
Boolean IsEmptyAt(int X, int Y) {
  if (Board[Y][X] == 0) {
    return true;
  } else {
    return false;
  }
}
int PieceAt(int[] Coord) {
  return Board[Coord[1]][Coord[0]];
}
Boolean CanMoveTwice(int Piece, int[] Coord) {
  Boolean IsWhite = Piece < 7;
  if (IsWhite) {
    if (Coord[1] == 6) {
      return true;
    }
  } else {
    if (Coord[1] == 1) {
      return true;
    }
  }
  return false;
}
Boolean IsSameTeam(int Piece, int[]Coord) {
  Boolean IsWhite = Piece < 7;
  int QueryPiece = Board[Coord[1]][Coord[0]];
  if (QueryPiece == 0) {
    return false;
  }
  if (IsWhite) {
    if (QueryPiece < 7) {
      return true;
    } else {
      return false;
    }
  } else {
    if (QueryPiece < 7) {
      return false;
    } else {
      return true;
    }
  }
}
int[][] GetQueenMoves(int Piece, int[] Coord) {
  return Combine(GetDirectionalMoves(Piece, Coord, DiagonalDirections), GetDirectionalMoves(Piece, Coord, LateralDirections));
}
int[][] GetPawnMoves(int Piece, int[] Coord) {
  int[][] TempValidMoves = new int[6][2];
  int ValidMoveIndex = 0;
  Boolean IsWhite = Piece < 7;
  int PawnDir = IsWhite ? -1 : 1;
  int[] ForwardPos = new int[2];
  ForwardPos[0] = Coord[0];
  ForwardPos[1] = Coord[1] + PawnDir;
  if (IsOnboard(ForwardPos[0], ForwardPos[1]) && PieceAt(ForwardPos) == 0) {
    TempValidMoves[ValidMoveIndex] = ForwardPos;
    ValidMoveIndex++;
  }
  if (CanMoveTwice(Piece, Coord)) {
    int[] ForwardPosTwice = new int[2];
    ForwardPosTwice[0] = Coord[0];
    ForwardPosTwice[1] = Coord[1] + PawnDir*2;
    if (ValidMoveIndex==1 && PieceAt(ForwardPosTwice) == 0) {
      TempValidMoves[ValidMoveIndex] = ForwardPosTwice;
      ValidMoveIndex++;
    }
  }
  int[][] PotentialCapturingMoves = {
    {Coord[0] - 1, ForwardPos[1]},
    {Coord[0] + 1, ForwardPos[1]},
  };
  for (int i = 0; i < PotentialCapturingMoves.length; i ++) {
    int[] PotCoord = PotentialCapturingMoves[i];
    if (!IsOnboard(PotCoord[0], PotCoord[1])) {
      continue;
    }
    int PotentialCaputrable = PieceAt(PotCoord);

    if (PotentialCaputrable != 0) {
      if (IsWhite) {
        if (PotentialCaputrable >= 7) {
          TempValidMoves[ValidMoveIndex] = PotCoord;
          ValidMoveIndex++;
        }
      } else {
        if (PotentialCaputrable < 7) {
          TempValidMoves[ValidMoveIndex] = PotCoord;
          ValidMoveIndex++;
        }
      }
    }
  }

  int[][] ValidMoves = new int[ValidMoveIndex][2];
  for (int i = 0; i < ValidMoveIndex; i++) {
    ValidMoves[i] = TempValidMoves[i];
  }
  return ValidMoves;
}
int[][] GetKingMoves(int Piece, int[] Coord) {
  int[][] KingMoves = Combine(LateralDirections, DiagonalDirections);
  int[][] TempValidMoves = new int[KingMoves.length][2];
  int ValidMoveIndex = 0;

  for (int i = 0; i < KingMoves.length; i++) {
    int[] CurrentDir = KingMoves[i];
    int[] NewCoord = Add(CurrentDir, Coord);
    if (IsOnboard(NewCoord[0], NewCoord[1]) && !IsSameTeam(Piece, NewCoord)) {
      TempValidMoves[ValidMoveIndex] = NewCoord;
      ValidMoveIndex++;
    }
  }
  int[][] ValidMoves = new int[ValidMoveIndex][2];
  for (int i = 0; i < ValidMoveIndex; i++) {
    ValidMoves[i] = TempValidMoves[i];
  }
  return ValidMoves;
}
int[][] GetKnightMoves(int Piece, int[] Coord) {
  int ValidMoveIndex = 0;
  int[][] TempValidMoves = new int[BoardSquares*BoardSquares][2];
  for (int i = 0; i < KnightMoves.length; i++) {
    int[] CurrentOffset = KnightMoves[i];
    int NewPosX = Coord[0] + CurrentOffset[0];
    int NewPosY = Coord[1] + CurrentOffset[1];
    if (!IsOnboard(NewPosX, NewPosY)) {
      continue;
    }
    int[] NewCoord = new int[2];
    NewCoord[0] = NewPosX;
    NewCoord[1] = NewPosY;
    if (IsEmptyAt(NewPosX, NewPosY) || (!IsSameTeam(Piece, NewCoord))) {
      TempValidMoves[ValidMoveIndex] = NewCoord;
      ValidMoveIndex++;
    }
  }
  int[][] ValidMoves = new int[ValidMoveIndex][2];
  for (int i = 0; i < ValidMoveIndex; i++) {
    ValidMoves[i] = TempValidMoves[i];
  }
  return ValidMoves;
}

int[][] GetDirectionalMoves(int Piece, int[] Coord, int[][] Directions) {
  int ValidMoveIndex = 0;
  int[][] TempValidMoves = new int[BoardSquares*BoardSquares][2];
  for (int i = 0; i < Directions.length; i++) {
    int[] CurrentDirection = Directions[i];
    int[] CurrentCoord = Coord;
    while (true) {
      CurrentCoord = Add(CurrentCoord, CurrentDirection);
      if (IsOnboard(CurrentCoord[0], CurrentCoord[1])) {
        if (PieceAt(CurrentCoord) != 0) {
          if (!IsSameTeam(Piece, CurrentCoord)) {
            TempValidMoves[ValidMoveIndex] = CurrentCoord;
            ValidMoveIndex++;
            break;
          } else {
            break;
          }
        } else {
          TempValidMoves[ValidMoveIndex] = CurrentCoord;
          ValidMoveIndex++;
        }
      } else {
        break;
      }
    }
  }
  int[][] ValidMoves = new int[ValidMoveIndex][2];
  for (int i = 0; i < ValidMoveIndex; i++) {
    ValidMoves[i] = TempValidMoves[i];
  }
  return ValidMoves;
}
Boolean IsBoardValid(Boolean IsWhite, int[][] Board) {
  int[] KingPosition = IsWhite ? KingPositions[0] : KingPositions[1];
  for (int i = 0; i < KnightMoves.length; i++) {
    int[] Offset = KnightMoves[i];
    int[] CurPos = Add(KingPosition, Offset);
    if (!IsOnboard(CurPos[0], CurPos[1])) {
      continue;
    }
    int PossibleKnight = PieceAt(CurPos);
    if (PossibleKnight != 0) {
      if (IsWhite) {
        if (PossibleKnight == 8) {
          return false;
        }
      } else {
        if (PossibleKnight == 2) {
          return false;
        }
      }
    }
  }

  for (int i = 0; i < DiagonalDirections.length; i++) {
    int[] CurrentDirection = DiagonalDirections[i];
    int[] CurrentCoord = KingPosition;
    while (true) {
      CurrentCoord = Add(CurrentCoord, CurrentDirection);
      if (!IsOnboard(CurrentCoord[0], CurrentCoord[1])) {
        break;
      }
      int PotentialBishopOrQueen = PieceAt(CurrentCoord);
      if (PotentialBishopOrQueen == 0) {
        continue;
      }
      if (IsWhite) {
        if (PotentialBishopOrQueen < 7) {
          break;
        }
        if (PotentialBishopOrQueen == 11 || PotentialBishopOrQueen == 9) {
          return false;
        } else {
          break;
        }
      } else {
        if (PotentialBishopOrQueen >= 7) {
          break;
        }
        if (PotentialBishopOrQueen == 5 || PotentialBishopOrQueen == 3) {
          return false;
        } else {
          break;
        }
      }
    }
  }

  for (int i = 0; i < LateralDirections.length; i++) {
    int[] CurrentDirection = LateralDirections[i];
    int[] CurrentCoord = KingPosition;
    while (true) {
      CurrentCoord = Add(CurrentCoord, CurrentDirection);
      if (!IsOnboard(CurrentCoord[0], CurrentCoord[1])) {
        break;
      }
      int PotentialRookOrQueen = PieceAt(CurrentCoord);
      if (PotentialRookOrQueen == 0) {
        continue;
      }
      if (IsWhite) {
        if (PotentialRookOrQueen < 7) {
          break;
        }
        if (PotentialRookOrQueen == 11 || PotentialRookOrQueen == 10) {
          return false;
        } else {
          break;
        }
      } else {
        if (PotentialRookOrQueen >= 7) {
          break;
        }
        if (PotentialRookOrQueen == 5 || PotentialRookOrQueen == 4) {
          return false;
        } else {
          break;
        }
      }
    }
  }
  int[][] KingMoves = Combine(LateralDirections, DiagonalDirections);
  for (int i = 0; i < KingMoves.length; i++) {
    int[] Offset = KingMoves[i];
    int[] CurPos = Add(KingPosition, Offset);
    if (!IsOnboard(CurPos[0], CurPos[1])) {
      continue;
    }
    int PotentialKing = PieceAt(CurPos);
    if (IsWhite) {
      if (PotentialKing == 12) {
        return false;
      }
    } else {
      if (PotentialKing == 6) {
        return false;
      }
    }
  }
  //add pawn thingo
  int PawnDir = IsWhite ? -1 : 1;
  int[][] PotentialCapturingMoves = {
    {KingPosition[0] - 1, KingPosition[1] + PawnDir},
    {KingPosition[0] + 1, KingPosition[1] + PawnDir},
  };
  for (int i = 0; i < PotentialCapturingMoves.length; i ++) {
    int[] PotCoord = PotentialCapturingMoves[i];
    if (!IsOnboard(PotCoord[0], PotCoord[1])) {
      continue;
    }
    int PotentialCaputrable = PieceAt(PotCoord);

    if (PotentialCaputrable != 0) {
      if (IsWhite) {
        if (PotentialCaputrable >= 7) {
          return false;
        }
      } else {
        if (PotentialCaputrable < 7) {
          return false;
        }
      }
    }
  }
  return true;
}
void OutBoard() {
  String Str = "\n";
  for (int y = 0; y < BoardSquares; y++) {
    for (int x = 0; x < BoardSquares; x++) {
      String Padding = Board[y][x] < 10 ? " " : "";
      Str += (Board[y][x] + Padding + ", ");
    }
    Str += "\n";
  }
  Str += "white king: " + KingPositions[0][0] + ", " + KingPositions[0][1] + "\n";
  Str += "black king: " + KingPositions[1][0] + ", " + KingPositions[1][1] + "\n";
  println(Str);
}
int[][] GetValidMovesForPiece(int Piece, int[] Coord) {
  int[][] SemanticValidMoves = {null};
  switch(Piece) {
  case 1: // white pawn
    SemanticValidMoves = GetPawnMoves(Piece, Coord);
    break;
  case 2: //white knight
    SemanticValidMoves = GetKnightMoves(Piece, Coord);
    break;
  case 3: // white bishop
    SemanticValidMoves = GetDirectionalMoves(Piece, Coord, DiagonalDirections);
    break;
  case 4: // white rook
    SemanticValidMoves = GetDirectionalMoves(Piece, Coord, LateralDirections);
    break;
  case 5: // white queen
    SemanticValidMoves = GetQueenMoves(Piece, Coord);
    break;
  case 6: // white king
    SemanticValidMoves = GetKingMoves(Piece, Coord);
    break;
  case 7: // black pawn
    SemanticValidMoves = GetPawnMoves(Piece, Coord);
    break;
  case 8: // black knight
    SemanticValidMoves = GetKnightMoves(Piece, Coord);
    break;
  case 9: // black bishop
    SemanticValidMoves = GetDirectionalMoves(Piece, Coord, DiagonalDirections);
    break;
  case 10: // black rook
    SemanticValidMoves = GetDirectionalMoves(Piece, Coord, LateralDirections);
    break;
  case 11: // black queen
    SemanticValidMoves = GetQueenMoves(Piece, Coord);
    break;
  case 12: //black king
    SemanticValidMoves = GetKingMoves(Piece, Coord);
    break;
  }
  Boolean IsWhite = Piece < 7;
  int Index = IsWhite ? 0 : 1;
  int[][] TempRealValidMoves = new int[BoardSquares*BoardSquares][2];
  int TempRealValidMovesIndex = 0;
  int[] OldKingPos = new int[2];
  OldKingPos[0] = KingPositions[Index][0];
  OldKingPos[1] = KingPositions[Index][1];

  for (int i = 0; i < SemanticValidMoves.length; i++) {
    int[] PotentialNewCoord = SemanticValidMoves[i];
    int OldVal = Board[PotentialNewCoord[1]][PotentialNewCoord[0]];
    Board[PotentialNewCoord[1]][PotentialNewCoord[0]] = Piece;
    Board[Coord[1]][Coord[0]] = 0;
    if (Piece == 6 || Piece == 12) {
      if (IsWhite) {
        KingPositions[0][0] = PotentialNewCoord[0];
        KingPositions[0][1] = PotentialNewCoord[1];
      } else {
        KingPositions[1][0] = PotentialNewCoord[0];
        KingPositions[1][1] = PotentialNewCoord[1];
      }
    }
    Boolean IsValid = IsBoardValid(IsWhite, Board);
    if (IsValid) {
      TempRealValidMoves[TempRealValidMovesIndex] = SemanticValidMoves[i];
      TempRealValidMovesIndex++;
    }
    Board[PotentialNewCoord[1]][PotentialNewCoord[0]] = OldVal;
    Board[Coord[1]][Coord[0]] = Piece;
    if (Piece == 6 || Piece == 12) {
      KingPositions[Index][0] = OldKingPos[0];
      KingPositions[Index][1] = OldKingPos[1];
    }
  }

  int[][] RealValidMoves = new int[TempRealValidMovesIndex][2];
  for (int i = 0; i < TempRealValidMovesIndex; i++) {
    RealValidMoves[i] = TempRealValidMoves[i];
  }
  return RealValidMoves;
}
void Move(int[] Start, int[] End) {
  int CorrespondingPiece = Board[Start[1]][Start[0]];
  if (Board[End[1]][End[0]] != 0){
    int CorrespondingIndex = PieceRenderVertsMap[End[1]][End[0]];
    for (int i = PieceVertsStarts[CorrespondingIndex]; i < PieceVertsStarts[CorrespondingIndex + 1]; i++){
      Verticies[i] = new float[]{0, 0, 0};
    }
  }
      if (CorrespondingPiece == 6) {
      KingPositions[0] = End;
    }

    if (CorrespondingPiece == 12) {
      KingPositions[1] = End;
    }

  Board[End[1]][End[0]] = CorrespondingPiece;
  Board[Start[1]][Start[0]] = 0;


  AnimRenderIndex = PieceRenderVertsMap[Start[1]][Start[0]];

  AnimVertStart = PieceVertsStarts[AnimRenderIndex];
  AnimVertEnd = PieceVertsStarts[AnimRenderIndex + 1];

  PieceRenderVertsMap[End[1]][End[0]] = AnimRenderIndex;
  PieceRenderVertsMap[Start[1]][Start[0]] = -1;

  int HalfBoardSize = (BoardSquares * BoardScale) / 2;

  float CenterX = 0;
  float CenterZ = 0;
  int count = AnimVertEnd - AnimVertStart;

  for (int v = AnimVertStart; v < AnimVertEnd; v++) {
    CenterX += Verticies[v][0];
    CenterZ += Verticies[v][2];
  }
  CenterX /= count;
  CenterZ /= count;
  float endX = End[0] * BoardScale - HalfBoardSize + BoardScale * 0.5;
  float endZ = -End[1] * BoardScale + HalfBoardSize - BoardScale * 0.5;
  AnimXs = Tween(CenterX, endX, AnimTotalFrames);
  AnimZs = Tween(CenterZ, endZ, AnimTotalFrames);
  LastX = CenterX;
  LastZ = CenterZ;
  AnimFrame = 0;
  IsMoving = true;
  AnimPieceStart = Start[1] * BoardSquares + Start[0];
  AnimPieceEnd = End[1] * BoardSquares + End[0];
    OutBoard();

}
String[] PieceNameMap = {
  "",
  "Pawn",
  "Knight",
  "Bishop",
  "Rook",
  "Queen",
  "King",
  "Pawn",
  "Knight",
  "Bishop",
  "Rook",
  "Queen",
  "King",
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


void setup() {
  size(800, 800);
  ZBuffer = new float[width][height];
  LoadBoardOBJ();
  pixelDensity(1);
}

float AngleToRad(float Angle) {
  return Angle * PI / 180;
}

int[] FaceToCoords(int SquareIndex) {
  int X = SquareIndex % BoardSquares;
  int Y = SquareIndex / BoardSquares;
  return new int[]{X, Y};
}
int CoordsToFace(int x, int y) {
  return y * BoardSquares + x;
}
int MaxPieces = BoardSquares * BoardSquares;
int[] PieceVertsStarts = new int[MaxPieces];
int PieceCount = 0;

int[][] PieceRenderVertsMap = new int[BoardSquares][BoardSquares];

void LoadBoardOBJ() {
  MaxDistance = 0;
  Verticies = null;
  Faces = null;
  PieceCount = 0;

  int[][] Verts = {
    {0, 0},
    {1, 0},
    {1, 1},
    {0, 1},
  };

  float BoardHeight = 0;
  int BoardThickness = 2;

  int HalfBoardSize = (BoardSquares * BoardScale) / 2;

  int TopVertCount = BoardSquares * BoardSquares * 4;
  int TopFaceCount = BoardSquares * BoardSquares * 2;

  int ExtraVerts = 8;
  int ExtraFaces = 12;

  int VertCount = TopVertCount + ExtraVerts;
  int FaceCount = TopFaceCount + ExtraFaces;

  Verticies = new float[VertCount][3];
  Faces = new int[FaceCount][3];

  int VertIndex = 0;
  int FaceIndex = 0;

  for (int y = 0; y < BoardSquares; y++) {
    for (int x = 0; x < BoardSquares; x++) {
      int CorrespondingPiece = Board[y][x];
      String CorrespondingName = PieceNameMap[CorrespondingPiece];

      if (CorrespondingPiece > 0) {
        int start = Verticies.length;
        if (CorrespondingPiece == 6) {
          KingPositions[0] = new int[]{x, y};
        }
        if (CorrespondingPiece == 12) {
          KingPositions[1] = new int[]{x, y};
        }
        PieceVertsStarts[PieceCount] = Verticies.length;
        PieceRenderVertsMap[y][x] = PieceCount;
        PieceCount++;
        LoadOBJ("../Objects/Pieces/" + CorrespondingName + ".obj");

        int end = Verticies.length;

        if (end > start) {
          float minY = Verticies[start][1];
          float maxY = Verticies[start][1];

          for (int i = start + 1; i < end; i++) {
            float yv = Verticies[i][1];
            if (yv < minY) minY = yv;
            if (yv > maxY) maxY = yv;
          }

          float px = x * BoardScale - HalfBoardSize + BoardScale * 0.5f;
          float pz = -y * BoardScale + HalfBoardSize - BoardScale * 0.5f;

          float py = BoardHeight - maxY;

          for (int i = start; i < end; i++) {
            Verticies[i][0] += px;
            Verticies[i][1] += py;
            Verticies[i][2] += pz;
          }
        }
      }

      int BaseIndex = VertIndex;

      for (int i = 0; i < Verts.length; i++) {
        int[] CurVert = Verts[i];

        int VertX = (x + CurVert[0]) * BoardScale;
        int VertZ = (y + CurVert[1]) * BoardScale;

        Verticies[VertIndex++] = new float[]{
          VertX - HalfBoardSize,
          BoardHeight,
          -VertZ + HalfBoardSize
        };
      }

      Faces[FaceIndex++] = new int[]{BaseIndex, BaseIndex + 1, BaseIndex + 2};
      Faces[FaceIndex++] = new int[]{BaseIndex, BaseIndex + 2, BaseIndex + 3};
    }
  }

  float MinX = -HalfBoardSize;
  float MaxX = HalfBoardSize;
  float MinZ = -HalfBoardSize;
  float MaxZ = HalfBoardSize;

  float TopY = BoardHeight;
  float BottomY = BoardHeight + BoardThickness;
  int Base = VertIndex;

  Verticies[VertIndex++] = new float[]{MinX, TopY, MinZ};
  Verticies[VertIndex++] = new float[]{MaxX, TopY, MinZ};
  Verticies[VertIndex++] = new float[]{MaxX, TopY, MaxZ};
  Verticies[VertIndex++] = new float[]{MinX, TopY, MaxZ};

  Verticies[VertIndex++] = new float[]{MinX, BottomY, MinZ};
  Verticies[VertIndex++] = new float[]{MaxX, BottomY, MinZ};
  Verticies[VertIndex++] = new float[]{MaxX, BottomY, MaxZ};
  Verticies[VertIndex++] = new float[]{MinX, BottomY, MaxZ};

  Faces[FaceIndex++] = new int[]{Base + 4, Base + 5, Base + 6};
  Faces[FaceIndex++] = new int[]{Base + 4, Base + 6, Base + 7};

  Faces[FaceIndex++] = new int[]{Base + 0, Base + 1, Base + 5};
  Faces[FaceIndex++] = new int[]{Base + 0, Base + 5, Base + 4};

  Faces[FaceIndex++] = new int[]{Base + 1, Base + 2, Base + 6};
  Faces[FaceIndex++] = new int[]{Base + 1, Base + 6, Base + 5};

  Faces[FaceIndex++] = new int[]{Base + 2, Base + 3, Base + 7};
  Faces[FaceIndex++] = new int[]{Base + 2, Base + 7, Base + 6};

  Faces[FaceIndex++] = new int[]{Base + 3, Base + 0, Base + 4};
  Faces[FaceIndex++] = new int[]{Base + 3, Base + 4, Base + 7};

  for (int i = 0; i < Verticies.length; i++) {
    float[] v = Verticies[i];
    float d = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (d > MaxDistance) MaxDistance = d;
  }
  CamDist = MaxDistance;
}
void LoadOBJ(String FilePath) {
  String[] Lines = loadStrings(FilePath);

  float[][] TempVerts = new float[Lines.length][3];
  int[][] TempFaces = new int[Lines.length * 4][3];

  int VertCount = 0;
  int FaceCount = 0;

  for (int l = 0; l < Lines.length; l++) {
    String line = trim(Lines[l]);

    if (line.startsWith("v ")) {
      String[] t = split(line, ' ');
      float x = float(t[1]);
      float y = -float(t[2]);
      float z = float(t[3]);

      TempVerts[VertCount++] = new float[]{x, y, -z};
    }

    if (line.startsWith("f ")) {
      String[] t = split(line, ' ');
      int n = t.length - 1;

      int[] idx = new int[n];
      for (int i = 0; i < n; i++) {
        String[] parts = split(t[i + 1], '/');
        idx[i] = int(parts[0]) - 1;
      }

      for (int i = 1; i < n - 1; i++) {
        TempFaces[FaceCount++] = new int[]{
          idx[0], idx[i], idx[i + 1]
        };
      }
    }
  }

  int VertOffset = (Verticies == null) ? 0 : Verticies.length;
  int FaceOffset = (Faces == null) ? 0 : Faces.length;

  float[][] NewVerts = new float[VertOffset + VertCount][3];
  int[][] NewFaces = new int[FaceOffset + FaceCount][3];

  if (Verticies != null) arrayCopy(Verticies, NewVerts);
  if (Faces != null) arrayCopy(Faces, NewFaces);

  for (int i = 0; i < VertCount; i++) {
    NewVerts[VertOffset + i] = TempVerts[i];
  }

  for (int i = 0; i < FaceCount; i++) {
    NewFaces[FaceOffset + i] = new int[]{
      TempFaces[i][0] + VertOffset,
      TempFaces[i][1] + VertOffset,
      TempFaces[i][2] + VertOffset
    };
  }

  Verticies = NewVerts;
  Faces = NewFaces;

  for (int i = 0; i < Verticies.length; i++) {
    float[] v = Verticies[i];
    float d = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
    if (d > MaxDistance) MaxDistance = d;
  }

  CamDist = MaxDistance;
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

int[] GetFaceColourChess(int FaceIndex) {
  if (FaceIndex < 138) {
    int BoardSquares = 8;
    int SquareIndex = FaceIndex / 2;
    int x = SquareIndex % BoardSquares;
    int y = SquareIndex / BoardSquares;

    int[] Col = ((x + y) % 2 == 0) ? new int[]{235, 236, 208} : new int[]{22, 99, 36};

    return Col;
  } else {
    int[] Col = {};

    if (FaceIndex < 5575) {
      Col = new int[]{54, 32, 16};
    } else {
      Col = new int[]{171, 140, 77};
    }
    return Col;
  }
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
  Frame ++;
  //RotX += AngleToRad(sin(RotAmount/50)*.25);
  //RotY += AngleToRad(1);
  loadPixels();
  ClearBackground(0xFFadab8c);
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
  if (IsMoving) {

  if (AnimFrame < AnimTotalFrames) {

    float nextX = AnimXs[AnimFrame];
    float nextZ = AnimZs[AnimFrame];

    float dx = nextX - LastX;
    float dz = nextZ - LastZ;

    for (int v = AnimVertStart; v < AnimVertEnd; v++) {
      Verticies[v][0] += dx;
      Verticies[v][2] += dz;
    }

    LastX = nextX;
    LastZ = nextZ;

    AnimFrame++;

  } else {
    float finalX = AnimXs[AnimTotalFrames - 1];
    float finalZ = AnimZs[AnimTotalFrames - 1];

    float fixDX = finalX - LastX;
    float fixDZ = finalZ - LastZ;

    for (int v = AnimVertStart; v < AnimVertEnd; v++) {
      Verticies[v][0] += fixDX;
      Verticies[v][2] += fixDZ;
    }

    int sx = AnimPieceStart % BoardSquares;
    int sy = AnimPieceStart / BoardSquares;
    int ex = AnimPieceEnd % BoardSquares;
    int ey = AnimPieceEnd / BoardSquares;

    int piece = Board[sy][sx];

    PieceRenderVertsMap[ey][ex] = AnimRenderIndex;
    PieceRenderVertsMap[sy][sx] = -1;


    WhitesMove = !WhitesMove;

    IsMoving = false;
  }

}
  DrawFaces(CurrentVerts);
  updatePixels();
  textSize(30);
  text(BaseText, 20, 30);
  text(RotInfo, 20, 70);
  text(OffInfo, 20, 110);
  text(FacesInfo, 20, 150);
  text(FPSInfo, 20, 190);
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
float[] Tween(float start, float end, int frames) {
  float[] result = new float[frames];
  if (frames == 1) {
    result[0] = end;
    return result;
  }
  for (int i = 0; i < frames; i++) { 
    float t = (float)i / (float)(frames - 1);
    result[i] = start + (end - start) * t;
  }
  return result;
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
int ClipTriangleNear(float[] A, float[] B, float[] C, float Near, float[][] Out1,float[][] Out2) {
  boolean AIn = A[2] >= Near;
  boolean BIn = B[2] >= Near;
  boolean CIn = C[2] >= Near;

  int Count = (AIn ? 1 : 0) + (BIn ? 1 : 0) + (CIn ? 1 : 0);
  if (Count == 0) return 0;
  if (Count == 3) {
    CopyVertex(Out1[0], A);
    CopyVertex(Out1[1], B);
    CopyVertex(Out1[2], C);
    return 1;
  }
  float[] I1 = new float[3];
  float[] I2 = new float[3];

  // 1 inside
  if (Count == 1) {
    float[] V0, V1, V2;

    if (AIn) { V0 = A; V1 = B; V2 = C; }
    else if (BIn) { V0 = B; V1 = C; V2 = A; }
    else { V0 = C; V1 = A; V2 = B; }

    Intersect(V0, V1, Near, I1);
    Intersect(V0, V2, Near, I2);

    CopyVertex(Out1[0], V0);
    CopyVertex(Out1[1], I1);
    CopyVertex(Out1[2], I2);

    return 1;
  }

  // 2 v inside
  if (Count == 2) {
    float[] V0, V1, V2;

    if (!AIn) { V0 = B; V1 = C; V2 = A; }
    else if (!BIn) { V0 = C; V1 = A; V2 = B; }
    else { V0 = A; V1 = B; V2 = C; }

    Intersect(V0, V2, Near, I1);
    Intersect(V1, V2, Near, I2);

    CopyVertex(Out1[0], V0);
    CopyVertex(Out1[1], V1);
    CopyVertex(Out1[2], I1);

    CopyVertex(Out2[0], V1);
    CopyVertex(Out2[1], I2);
    CopyVertex(Out2[2], I1);

    return 2;
  }

  return 0;
}
void Intersect(float[] V1, float[] V2, float Near, float[] Out) {
  float t = (Near - V1[2]) / (V2[2] - V1[2]);

  Out[0] = V1[0] + t * (V2[0] - V1[0]);
  Out[1] = V1[1] + t * (V2[1] - V1[1]);
  Out[2] = Near;
}

void CopyVertex(float[] Dest, float[] Src) {
  Dest[0] = Src[0];
  Dest[1] = Src[1];
  Dest[2] = Src[2];
}

int HoveredSquare = -1;
Boolean AssignedHoveredSquare = false;
void DrawFaces(float[][] V) {
  TriTally = 0;

  float LightDirectionX = 1;
  float LightDirectionY = -.5;
  float LightDirectionZ = -.25;

  float LightLength = sqrt(LightDirectionX * LightDirectionX + LightDirectionY * LightDirectionY + LightDirectionZ * LightDirectionZ);

  LightDirectionX /= LightLength;
  LightDirectionY = -LightDirectionY / LightLength;
  LightDirectionZ /= LightLength;

  int FaceCount = Faces.length;

  float[] Weights = new float[3];
  if (!AssignedHoveredSquare) {
    HoveredSquare = -1;
  }
  AssignedHoveredSquare = false;

  float Near = 0.01f;

  for (int FaceIndex = 0; FaceIndex < FaceCount; FaceIndex++) {
    int[] face = Faces[FaceIndex];

    int VertexIndexA = face[0];
    int VertexIndexB = face[1];
    int VertexIndexC = face[2];

    float[][] T1 = new float[3][3];
    float[][] T2 = new float[3][3];

    int ClippedCount = ClipTriangleNear(V[VertexIndexA], V[VertexIndexB], V[VertexIndexC], Near, T1, T2);

    for (int t = 0; t < ClippedCount; t++) {

      float[][] tri = (t == 0) ? T1 : T2;

      float[] VertexA = tri[0];
      float[] VertexB = tri[1];
      float[] VertexC = tri[2];

      float DepthA = VertexA[2];
      float DepthB = VertexB[2];
      float DepthC = VertexC[2];

      float[] ScreenA = WorldToScreen(VertexA);
      float[] ScreenB = WorldToScreen(VertexB);
      float[] ScreenC = WorldToScreen(VertexC);

      int ScreenAX = (int)ScreenA[0];
      int ScreenAY = (int)ScreenA[1];

      int ScreenBX = (int)ScreenB[0];
      int ScreenBY = (int)ScreenB[1];

      int ScreenCX = (int)ScreenC[0];
      int ScreenCY = (int)ScreenC[1];

      if ((ScreenAX < 0 && ScreenBX < 0 && ScreenCX < 0) || (ScreenAX >= width && ScreenBX >= width && ScreenCX >= width) || (ScreenAY < 0 && ScreenBY < 0 && ScreenCY < 0) || (ScreenAY >= height && ScreenBY >= height && ScreenCY >= height)) {
        continue;
      }

      int MinimumX = max(0, min(ScreenAX, min(ScreenBX, ScreenCX)));
      int MaximumX = min(width - 1, max(ScreenAX, max(ScreenBX, ScreenCX)));

      int MinimumY = max(0, min(ScreenAY, min(ScreenBY, ScreenCY)));
      int MaximumY = min(height - 1, max(ScreenAY, max(ScreenBY, ScreenCY)));

      float denom = (ScreenB[1] - ScreenC[1]) * (ScreenA[0] - ScreenC[0]) + (ScreenC[0] - ScreenB[0]) * (ScreenA[1] - ScreenC[1]);

      if (denom == 0) {
        continue;
      }
      if (RenderType == 0) {
        DrawLine(ScreenAX, ScreenAY, ScreenBX, ScreenBY);
        DrawLine(ScreenBX, ScreenBY, ScreenCX, ScreenCY);
        DrawLine(ScreenCX, ScreenCY, ScreenAX, ScreenAY);
        continue;
      }
      
      float InverseDenom = 1.0 / denom;

      float[] ModelVertexA = VertexA;
      float[] ModelVertexB = VertexB;
      float[] ModelVertexC = VertexC;

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
      float Intensity = 0.9;
      float Brightness = NormalX * LightDirectionX + NormalY * LightDirectionY + NormalZ * LightDirectionZ;

      if (Brightness < 0) {
        Brightness = 0;
      }
      TriTally++;
      Brightness = 0.2 + Brightness * Intensity;

      int[] BaseColor = GetFaceColourChess(FaceIndex);

      int SquareIndex = FaceIndex / 2;
      float RedOut   = BaseColor[0] * Brightness;
      float GreenOut = BaseColor[1] * Brightness;
      float BlueOut  = BaseColor[2] * Brightness;
      if (FaceIndex < 128) {
        if (IsInsideTriangle(mouseX + 0.5, mouseY + 0.5, ScreenA, ScreenB, ScreenC, InverseDenom, Weights)) {
          HoveredSquare = FaceIndex / 2;
          AssignedHoveredSquare = true;
        }
      }
      if (FaceIndex < 128) {
        if (SquareIndex == HoveredSquare) {
          GreenOut = 255;
        }
      }
      int[] CorrespondingCoords = FaceToCoords(SquareIndex);
      if(CorrespondingCoords[0] == MovingPieceX && CorrespondingCoords[1] == MovingPieceY){
        RedOut = 209;
        GreenOut = 82;
        BlueOut = 82;
      }
      if (IntInArr(FacesToColour, FaceIndex)){
        RedOut = 227;
        GreenOut = 190;
        BlueOut = 126;
      }

      for (int PixelY = MinimumY; PixelY <= MaximumY; PixelY++) {
        float py = PixelY + 0.5;
        for (int PixelX = MinimumX; PixelX <= MaximumX; PixelX++) {
          float px = PixelX + 0.5;
          if (!IsInsideTriangle(px, py, ScreenA, ScreenB, ScreenC, InverseDenom, Weights)) {
            continue;
          }
          float w1 = Weights[0];
          float w2 = Weights[1];
          float w3 = Weights[2];
          float RealDepthValue = w1 * DepthA + w2 * DepthB + w3 * DepthC;

          if (RealDepthValue >= ZBuffer[PixelX][PixelY]) {
            continue;
          }
          ZBuffer[PixelX][PixelY] = RealDepthValue;
          int PixelIndex = PixelY * width + PixelX;
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
void mousePressed() {
  if (HoveredSquare < 0 || HoveredSquare > 64){
    MovingPiece = false;
        MovingPieceX = -1;
    MovingPieceY = -1;
      FacesToColour = new int[0];

    return;
  }
  int[] PressedCoord = FaceToCoords(HoveredSquare);
  int PressedX = PressedCoord[0];
  int PressedY = PressedCoord[1];
  int CorrespondingPiece = Board[PressedY][PressedX];
  Boolean CorrespondingPieceIsWhite = CorrespondingPiece < 7;
  if (!MovingPiece) {
    if ((CorrespondingPieceIsWhite && !WhitesMove) || (!CorrespondingPieceIsWhite && WhitesMove)) {
      return;
    }
    if (CorrespondingPiece != 0) {
      MovingPiece = true;
      MovingPieceX = PressedX;
      MovingPieceY = PressedY;
      int[] CorrespondingCoord = new int[2];
      CorrespondingCoord[0] = PressedX;
      CorrespondingCoord[1] = PressedY;
      int[][] ValidMoves = GetValidMovesForPiece(CorrespondingPiece, CorrespondingCoord);
      PrevValidMoves = ValidMoves;
      FacesToColour = new int[ValidMoves.length*2];
      int FacesToColourIdx = 0;
      for (int i = 0; i < ValidMoves.length; i++) {
        int[] CurValidMove = ValidMoves[i];
        int Face = CoordsToFace(CurValidMove[0], CurValidMove[1]);
        int RealFace1 = Face*2;
        int RealFace2 = RealFace1+1;
        FacesToColour[FacesToColourIdx] = RealFace1;
        FacesToColour[FacesToColourIdx+1] = RealFace2;
        FacesToColourIdx+=2;
      }
    }
  } else {
    int[] OriginalPos = new int[2];
    OriginalPos[0] = MovingPieceX;
    OriginalPos[1] = MovingPieceY;
    int[] NewPos = new int[2];
    NewPos[0] = PressedX;
    NewPos[1] = PressedY;
    if (PrevValidMoves != null) {
      FacesToColour = new int[0];
    }
    if (IsCoordInSet(PrevValidMoves, NewPos)) {
      Move(OriginalPos, NewPos);
    } 
    MovingPiece = false;
    MovingPieceX = -1;
    MovingPieceY = -1;
  }
}