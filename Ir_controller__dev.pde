import processing.serial.*; //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//

/*
          LAYERS
 0 Reserved at present
 1 Outlines including buttons where only partthereof is functional 
 2 Clickable items -Buttons, Active Text
 3 Passive Text
 4 Hidden Buttons - No Text and no outline shown unless clicked
 5 Text Input Fields
 9n Design mode items   - n is level number from standard items above
 
 */


color buttonColor, baseColor, tfc;
color buttonHighlight;
color currentColor, buttonFillColor, textFillColor;

String buttonColorText, textColorText;
String bType, irHex, bText, textColorTexttext, manCode;
String says="";
String textMessage = "Initialised";



int x, y, w, h, tSize, order;
int i, j, k, strokeWt, rectRadius;
int xMouse = 0;
int yMouse =0;
int layer;
int noNavigateRows, noLayoutRows, noColorRows, noScheduleRows;
int lastButtonIndex = -1;
boolean buttonIsInFocus, status;
Boolean setUp = true;
Boolean recording = false;
Boolean textInput = false;
Boolean textEntryInProgress = false ;
// provide for 5 sets of up to 5 radio buttons
Boolean [][] radioButtonStates = new Boolean [5][5];
int [] radioButtonLayers = new int [5];
int [][] radioButtonNos = new int [5][5];
int [] noOfButtonsInLayer = new int [5];
int radioButtonLayer=0;
int radioButtonNo =0, lastRBLayer=-1, lastRBNo=-1, bNoIndex =-1, bLayerIndex=-1;



String [] direction = new String[5];
String signPosts = "UDLRO";
String ch, tHex;
int curCol = 0;
int curRow = 0;
int col, row;  
int nRows, nCols, nChars;
String spacePos, linkLetter, keyOrder;
// Variables for Schedule Table
String buttonTexts = "";
String buttonNos = "";
String buttonHex = "";
String hexString = "";
int sMM, sHH, sMinute, sHour, HH, MM;

int [] tableList = new int[10];
int noTables = 0; 
int lRow;
String keyboardName;



Serial myPort;
Table layoutTable, scheduleTable, colorTable, navigateTable, scratch;


void setup() {

  size(1500, 1000);
  PFont font1 = createFont("Calibri", 16);
  layoutTable = loadTable("layout.csv", "header");
  noLayoutRows = layoutTable.getRowCount();
  layoutTable.sort(2);
  scheduleTable = loadTable("Schedule.csv", "header");
  noScheduleRows = scheduleTable.getRowCount();
  scheduleTable.sort(4);
  colorTable = loadTable("Color.csv", "header");
  noColorRows = colorTable.getRowCount();
  navigateTable = loadTable("Keyboard Definitions.csv", "header");
  noNavigateRows = navigateTable.getRowCount();//
  myPort = new Serial(this, Serial.list()[0], 9600);
  // Draw Buttons and Label
  buttonColor = color(0);
  buttonFillColor =buttonColor;
  buttonHighlight = color(255, 0, 0);
  currentColor= color(128);
  ellipseMode(CENTER);
  rectMode(CENTER);
  background(currentColor);

  textFont(font1);
  textSize(32);
  strokeWeight(2);
  for ( lRow = 0; lRow < noLayoutRows; lRow = lRow +1) {
    getRowData();
    drawButton();
    if (bType.equals("TD")==true) { 
      tableList[noTables++] = lRow;
    }
    if (bType.equals("RB")==true) {
      if (layer != radioButtonLayer) {
        radioButtonLayer = layer;
        bLayerIndex++;
        radioButtonLayers[bLayerIndex] = layer;

        bNoIndex = -1;
      }
      bNoIndex++;
      noOfButtonsInLayer[bLayerIndex] = bNoIndex+1;
      radioButtonNos[bLayerIndex][bNoIndex] = lRow;
      if (bText.equals("OFF") ==true) {
        radioButtonStates[bLayerIndex][bNoIndex] = false;
      } else {
        radioButtonStates[bLayerIndex][bNoIndex] = true;
      }
    }
  }
  displayTable();
  setUp = false;
  frameRate(5);
  checkSchedule();
  if (hexString.equals("") == false) {
    sendToArduino(hexString, status);
  }
}

void draw() {
  if (mousePressed == true) {
    xMouse = mouseX;
    yMouse =mouseY;
  }
  if (frameCount%5 == 0) {
    checkSchedule();
    if (hexString.equals("") == false) {
      sendToArduino(hexString, status);
    }
  }
  if (textMessage.equals("") == false) {
    progressMessage(textMessage);
    textMessage ="";
  }
  if (frameCount%5 == 0) {
    String timeDisplay = nf(hour(), 2)+":"+nf(minute(), 2)+":"+nf(second(), 2);
    fill(getColor("B", 255));
    rect(830, 900, 90, 28);
    drawText(timeDisplay, 830, 900, CENTER, CENTER, 22, "Y");
  }
}
void mouseReleased() {
  int xx, yy;
  if (mouseButton == RIGHT && recording == true) {
    updateScheduleTable();
    recording = false;
  } else {
    if (textEntryInProgress = false) {
    }
    if (lastButtonIndex >= 0 ) {
      lRow = lastButtonIndex; //<>//
buttonFillColor = currentColor;
      drawOneButton(lastButtonIndex);
    }
    if (textEntryInProgress == false) {
      println(xMouse + " "+ yMouse);
      delay(40);
      for ( lRow = 0; lRow < noLayoutRows; lRow++) {
        getRowData();
        if (clickedOnButton()== true) { 
          // means we have found the button clicked
          lastButtonIndex = lRow;
          switch(bType) {
          case "TB":
            buttonFillColor =buttonHighlight;
            textMessage = "Enter Text followed by ENTER";
            drawOneButton(lRow);
            says="";
            break;
          case "TD":
            buttonFillColor =buttonHighlight;
            drawOneButton(lRow);
            displayTable();
            break;
          case "RB":
            println("RB");
            processRadioButton();
            break;
          default:
            drawOneButton(lRow);
            if (irHex.length() > 0 ) {
              if (recording == true) {
                buttonTexts += bText+ "*";
                buttonNos += str(lRow) + "*";
                buttonHex += irHex+ " ";
              } else {
                sendToArduino(irHex, status);
                buttonFillColor =buttonHighlight;
              }
            }
          }
          stroke(0);
          drawButton();
          break;
        }
      }
    }
  }
}

void processRadioButton() {
  int xx, yy;
  for ( xx=0; xx<= bLayerIndex; xx++) {
    if (layer == radioButtonLayers[xx]) {

      for ( yy=0; yy<noOfButtonsInLayer[xx]; yy++) {
        int thisButtonNo = radioButtonNos[xx][yy];
        if (thisButtonNo == lRow) {
          buttonFillColor = getColor("G", 255);
          radioButtonStates[xx][yy] = true;
          layoutTable.setString(thisButtonNo, 8, "ON");
          keyboardName   = layoutTable.getString(lRow,10);
          //        break;
        } else {
          buttonFillColor = getColor("R", 255);
          radioButtonStates[xx][yy] = false;
          layoutTable.setString(thisButtonNo, 8, "OFF");
        }
      }
      for (int bNo = 0; bNo < noOfButtonsInLayer[xx]; bNo++) {
        int actBno = radioButtonNos[xx][bNo];
        drawOneButton(actBno);
      }
      break;
    }
  }
}

boolean clickedOnButton()
{
  if (setUp == true) {
    return false;
  }
  buttonIsInFocus = false;
  if (irHex.length() > 0  || bType.equals("TB")|| bType.equals("RB")) 
  {
    switch(bType)
    {
    case "R":
    case "TB":
      if (xMouse >=x-w/2 && xMouse <= x+w/2 && yMouse >= y-h/2 && yMouse <= y+h/2)
      {
        buttonIsInFocus = true;
      }
      break;   
    case "C":
      float disX = x - xMouse;
      float disY = y - yMouse;
      float hypoteneuse = sqrt(sq(disX) +sq(disY));
      if ( hypoteneuse < w/2 )
      {
        buttonIsInFocus =true;
      }
      break;
    case "RB":
      disX = x - xMouse;
      disY = y - yMouse;
      hypoteneuse = sqrt(sq(disX) +sq(disY));
      if ( hypoteneuse < w/2 )
      {
        buttonIsInFocus =true;
      }
      break;
    }
  }
  if (buttonIsInFocus) 
  {
    buttonFillColor =buttonHighlight;
    return true;
  } else {
    return false;
  }
}

void drawButton()
{
  if (!buttonIsInFocus)
  {
    getButtonFillColor();
  }
  fill(buttonFillColor);
  stroke(255);
  if (strokeWt > 0) {
    strokeWeight(strokeWt);
  } else {
    strokeWeight(2);
  }
  switch(bType) {
  case "R":
  case "TB":
  case "TD":
    rect(x, y, w, h, rectRadius);
    if (bType.equals("TD")== true) {
      displayTable();
    }
    break;
  case "E":
    ellipse(x, y, w, h);
    break;
  case "C":
    circle(x, y, w);
    break;
  case "RB":
    stroke(255);
    strokeWeight(5);
    String buttonStatus = layoutTable.getString(lRow, 8);
    if (buttonStatus.equals("ON")==false) {
      buttonFillColor = getColor("R", 255);
      println(lRow+" OFF");
    } else {
      buttonFillColor = getColor("G", 255);
      println(lRow+" ON");
    }
    fill(buttonFillColor);

    circle(x, y, w);
    break;
  }
  getTextFillColor();
  fill(textFillColor);
  if (tSize > 0) {

    String s = bText;

    drawText(s, x, y, CENTER, CENTER, tSize, textColorText);
  }
}

void getRowData() {
  if (lRow >= noLayoutRows) {
    print("warning lRow is out of bounds "+lRow);
    return;
  }
  TableRow row = layoutTable.getRow(lRow);
  x= row.getInt(4);
  y= row.getInt(5);
  bType =row.getString(3);
  layer = row.getInt(2);
  w = row.getInt(6);
  h= row.getInt(7);
  bText =row.getString(8);
  tSize =row.getInt(9);
  irHex = row.getString(10);
  rectRadius = row.getInt(11);
  strokeWt = row.getInt(12);
  buttonColorText = row.getString(13);
  textColorText = row.getString(14);
  manCode =row.getString(15);
}
//
// send to Arduino
//
void sendToArduino(String irHex, Boolean status) { 

  String hexVal;
  while (irHex.length() != 0) 
  {
    irHex = irHex.substring(2);
    int nextValIndex= irHex.indexOf("0x");
    if (nextValIndex == -1) {
      hexVal = trim(irHex);
      irHex="";
    } else
    {
      hexVal = trim(irHex.substring(0, nextValIndex));

      irHex = irHex.substring(nextValIndex);
    }
    int iData = unhex(hexVal);
    println(order+" "+hexVal+"  "+iData);
    // Byte enq = '5';

    //  myPort.write(enq);
    //   int ready = myPort.readChar();
    //   while (ready != '6')
    // {
    //   }


    myPort.write(str(iData)+manCode);
    delay(250);
    hexVal = "";
  }
  irHex="";
  status = true;
}

void getButtonFillColor()
{
  buttonFillColor =color( getColor(buttonColorText, buttonColor));
}

void getTextFillColor()
{ 
  textFillColor = getColor(textColorText, 255);
}

void drawAllButtons() {
  for ( lRow = 0; lRow < noLayoutRows; lRow++) {
    getRowData();
    drawButton();
  }
}
void drawOneButton(int buttonNo ) {
  lRow= buttonNo; //<>//
  String tText=bText;
  Boolean highLight = false;
  if (buttonFillColor ==buttonHighlight) {
    highLight = true;
  }
  if (buttonFillColor==currentColor){
    highLight=false;
  }
  getRowData();
  if (bType.equals("RB") == false ) {
    getButtonFillColor();
    getTextFillColor();
    if (highLight == true) {
      buttonFillColor =buttonHighlight;
    }
    if (tText.equals("") == true) {
      bText=tText;
    }
  } else {
  }
  drawButton();
}
color getColor(String colorCode, color defaultColor) {
  color colorValue;
  if (colorCode.equals("") == true) {
    return defaultColor;
  }
  TableRow result = colorTable.matchRow(colorCode, "Code");
  if (result== null) {
    colorValue = defaultColor;
    return colorValue;
  }
  String colorHex =result.getString("Number"); 
  if (colorHex.equals("") ==true) {
    int greyScale = result.getInt("GreyScale");
    if (greyScale <0 || greyScale > 255) {
      colorValue = defaultColor;
      return colorValue;
    } else {
      colorValue = greyScale;
    }
  } else {
    colorValue = unhex(colorHex.substring(2));
  }
  return colorValue;
}
void navigate(String searchText)
{
  int i;
  TableRow result = navigateTable.matchRow(keyboardName, "AppName");
  if (result== null) {
    return ;
  }
  nRows = result.getInt(2);
  nCols = result.getInt(3);
  spacePos = result.getString(4).substring(0, 1);
  linkLetter = result.getString(5);
  direction[0] = result.getString(6);
  direction[1] = result.getString(7);
  direction[2] = result.getString(8);
  direction[3] = result.getString(9);
  direction[4] = result.getString(10);
  String toHomeSeq = result.getString(11);
  String fromHomeSeq = result.getString(12);
  keyOrder = result.getString(13);
  //
  // send the initialisation hex strings
  irHex = "";
  for (i = 0; i< fromHomeSeq.length(); i++)
  {
    ch = fromHomeSeq.substring(i, i+1);
    j = signPosts.indexOf(ch);
    //    irHex = irHex+direction[j]+" ";
    sendToArduino(direction[j], status);

    println(ch);
  }
  for (i = 0; i< toHomeSeq.length(); i++)
  {
    ch = toHomeSeq.substring(i, i+1);
    j = signPosts.indexOf(ch);
    //    irHnex = irHex+direction[j]+" ";
    sendToArduino(direction[j], status);
    println(ch);
  }
  // Translate the text into movement commands
  curRow =0;
  curCol = 0;
  nChars = searchText.length();
  for ( int cPos = 0; cPos< nChars; cPos++)
  {
    ch = searchText.substring(cPos, cPos+1);
    if (ch.equals(" ") == true) {
      handleSpace();
    } else {
      ch = ch.toUpperCase();
      print(ch+" ");
      navigateToCharacter(ch);
      sendToArduino(direction[4], status);
    }
  }
}
//
//
void navigateToCharacter(String ch) {

  int  j, k, ups, lefts;
  j = keyOrder.indexOf(ch);
  row = j/nRows;
  col = j%nCols;
  ups = curRow - row;//ups will be negative for downward movement
  lefts = curCol - col;// lefts will be negative for rightwards movement
  curRow = row;
  curCol = col;
  if (ups != 0) {
    if (ups < 0 ) {
      tHex = direction[1];
      ups = ups* -1;
    } else {
      tHex = direction[0];
    }
    for (k = 0; k<ups; k++) {
      //irHex = irHex + tHex +" ";
      sendToArduino(tHex, status);
    }
  }
  if (lefts != 0) {
    if (lefts < 0 ) {
      tHex = direction[3];
      lefts = lefts* -1;
    } else {
      tHex = direction[2];
    }
    for (k = 0; k<lefts; k++) {
      //irHex = irHex + tHex +" ";
      sendToArduino(tHex, status);
    }
  }
}
//
void handleSpace() {
  //
  // Navigate to LINK CHARACTER AND THEN TAKE DIRECTION FROM THERE

  //
  navigateToCharacter(linkLetter);
  j = signPosts.indexOf(spacePos);
  if (j >= 0) {
    sendToArduino(direction[j], status);
    sendToArduino(direction[4], status);
    switch(j) {
    case 0:
      j=1;
      break;
    case 1:
      j=0;
      break;
    case 2:
      j=3;
      break;
    case 3:
      j=2;
      break;
    }
    sendToArduino(direction[j], status);
  }
}

void keyPressed() {
  if (textEntryInProgress == false) {

    textEntryInProgress = !textEntryInProgress;
    bText="";
    if (lRow < noLayoutRows) {
      drawOneButton(lRow);
    }
    drawText(says, x-w/2, y, LEFT, CENTER, tSize, textColorText);
    says = "";
  }
  switch(key) {
  case BACKSPACE:
    int stLength = says.length();
    if (stLength> 0 ) {
      says = says.substring(0, stLength-1);
    }
    drawOneButton(lRow);
    drawText(says, x-w/2, y, LEFT, CENTER, tSize, textColorText);
    break;
  case ENTER:
    textEntryInProgress = !textEntryInProgress;

    switch(layer) {
    case 99:
      navigate(says);
      break;
    case 9999:
      if (validateTime() == true) {
        recording = true;
        textMessage ="Recording in Progress - Right Click to Terminate";
      } else {
      }
    }
  case RETURN:
    textEntryInProgress = !textEntryInProgress;
    break;
  default:
    if ( key != CODED ) {
      says += key;
      drawText(says, x-w/2, y, LEFT, CENTER, tSize, textColorText);
    }
  }
}

Boolean validateTime() {
  String scheduleTime  = says;
  if (says.length() !=4) {
    return false;
  }
  scratch = new Table();
  scratch.addColumn("HH");
  scratch.addColumn("MM");
  TableRow newRow = scratch.addRow();
  newRow.setString(0, scheduleTime.substring(0, 2));
  newRow.setString(1, scheduleTime.substring(2));
  saveTable(scratch, "data/scratch.csv");
  scratch = loadTable("scratch.csv", "header");
  TableRow row = scratch.getRow(0);

  HH = row.getInt(0);

  MM = row.getInt(1);
  if (HH < 0 || HH> 23) {
    return false;
  }
  if (MM < 0 || MM > 59) {
    return false;
  }
  return true;
}

void  updateScheduleTable() {

  textMessage = "updating";
  TableRow newRow = scheduleTable.addRow();
  newRow.setString(0, buttonNos);
  newRow.setString(1, buttonTexts);
  newRow.setInt(2, HH);
  newRow.setInt(3, MM);
  int baseTime = 10000;
  baseTime = baseTime + (HH * 100) + MM;
  newRow.setInt(4, baseTime);
  newRow.setString(8, buttonHex);
  newRow.setString(9, manCode);
  saveTable(scheduleTable, "data/Schedule.csv");
  scheduleTable.sort(4);
  displayTable();
  buttonTexts = "";
  buttonNos = "";
  buttonHex = "";
}
void checkSchedule() {
  hexString="";
  noScheduleRows = scheduleTable.getRowCount();
  if (noScheduleRows > 0) {
    TableRow row = scheduleTable.getRow(0);
    sHH= row.getInt(2);
    sMM = row.getInt(3);
    sHour=hour();
    sMinute = minute();
    if ((sHour == sHH &&sMinute >= sMM) || sHour > sHH) {
      hexString = row.getString(8);

      scheduleTable.removeRow(0);
      saveTable(scheduleTable, "data/Schedule.csv");
      displayTable();
    }
  }
  return;
}
void displayTable() {

  // get and parse table description
  // format is { Table Name; No of Rows, Row Height, Text Height;repeated Column Ni, Pixel offset from recatngle left edge, No of Pixels wide;....
  //
  for (int tableNo=0; tableNo<noTables; tableNo++) {
    lRow = tableList[tableNo];
    getRowData();

    getButtonFillColor();
    getTextFillColor();
    fill(buttonFillColor);
    rect(x, y, w, h);
    String [] params = split(irHex, ";");
    String [] tableSpec = split( params[0], ",");
    String tableName =tableSpec[0];
    int sortColumn = int(tableSpec[1]);
    Table tempTable =  loadTable(tableName+".csv", "header");
    tempTable.sort(sortColumn);
    int noTableRows = tempTable.getRowCount();
    int [] nums = int(split(params[1], ","));
    int  noRows = nums[0];
    int rowHeight = nums[1];
    int textHeight = nums[2];
    int nCols = params.length-2;
    for (int ix = 0; ix < nCols; ix++) {
      int col = ix;
      if (noTableRows < noRows) {
        noRows = noTableRows;
      }
      for (j= 0; j<noRows; j++) {
        nums = int(split(params[col+2], ","));
        int colNo = nums[0];
        int pixelOffsetX = nums[1];
        int pixelWidth = nums[2];
        int leadZeroFill = 0;
        if (nums.length > 3) {
          leadZeroFill = nums[3];
        }
        TableRow row = tempTable.getRow(j);
        String butText = row.getString(colNo); 
        int yy=y-(h/2)+5+(rowHeight/2)*(j+1);
        int xx=x-(w/2)+pixelOffsetX;
        if (leadZeroFill >0) {
          int butInt = int(butText);
          butText =nf(butInt, leadZeroFill);
        } 
        drawText(butText, xx, yy, LEFT, CENTER, textHeight, "Y");
      }
    }
  }
}

void progressMessage(String message) {
  stroke(1);
  fill(255, 0, 0);
  rect(1100, 900, 700, 50);
  drawText(message, 1100, 900, CENTER, CENTER, 22, "Y");
  return;
}
void drawText(String dText, int x, int y, int hAlign, int vAlign, int tSize, String cCode) {
  fill(getColor(cCode, 255));
  textSize(tSize);
  textAlign(hAlign, vAlign);
  text(dText, x, y);
  return;
}
void radioButtons() {
}
Boolean getRadioButtonStatus() {
  int xx, yy;
  Boolean returnState =  false;
  for ( xx=0; xx< bLayerIndex; xx++) {
    if (layer == radioButtonLayers[xx]) {

      for ( yy=0; yy<noOfButtonsInLayer[xx]; yy++) {


        if (radioButtonNos[xx][yy] == lRow) {
          buttonFillColor = getColor("G", 255);
          radioButtonStates[xx][yy] = true;
          returnState=true;
        } else {
          buttonFillColor = getColor("R", 255);
          radioButtonStates[xx][yy] = false;
        }
      }
    }
  }
  return returnState;
}
